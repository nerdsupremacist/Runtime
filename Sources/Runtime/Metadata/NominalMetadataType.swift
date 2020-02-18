// MIT License
//
// Copyright (c) 2017 Wesley Wickwire
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import CwlDemangle

private let unsupportedModules: Set<String> = [
    "__C",
    "Swift",
    "Dispatch",
    "CwlDemangle",
    "Runtime",
    "NIO",
    "LeoQL",
    "GraphQL",
]

protocol NominalMetadataType: MetadataType where Layout: NominalMetadataLayoutType {
    
    /// The offset of the generic type vector in pointer sized words from the
    /// start of the metadata record.
    var genericArgumentOffset: Int { get }
}

extension NominalMetadataType {
    
    var genericArgumentOffset: Int {
        // default to 2. This would put it right after the type descriptor which is valid
        // for all types except for classes
        return 2
    }
    
    var isGeneric: Bool {
        return (pointer.pointee.typeDescriptor.pointee.flags & 0x80) != 0
    }
    
    var genericContextHeader: TargetTypeGenericContextDescriptorHeader {
        return getTypeDescTrailingObject(at: 0, as: TargetTypeGenericContextDescriptorHeader.self)
    }
    
    var vtableHeader: TargetVTableDescriptorHeader {
        let genericOffset = isGeneric
            ? MemoryLayout<TargetTypeGenericContextDescriptorHeader>.size
            : 0
        
        return getTypeDescTrailingObject(at: genericOffset, as: TargetVTableDescriptorHeader.self)
    }

    var vtable: UnsafeMutableBufferPointer<UnsafeRawPointer> {
        let vTableDesc = vtableHeader

        let vtableStart = pointer
            .advanced(by: Int(vTableDesc.vTableOffset), wordSize: MemoryLayout<UnsafeRawPointer>.size)
            .assumingMemoryBound(to: UnsafeRawPointer.self)

        return UnsafeMutableBufferPointer<UnsafeRawPointer>(start: vtableStart, count: Int(vTableDesc.vTableSive))
    }
    
    mutating func mangledName() -> String {
        return String(cString: pointer.pointee.typeDescriptor.pointee.mangledName.advanced())
    }
    
    mutating func numberOfFields() -> Int {
        return Int(pointer.pointee.typeDescriptor.pointee.numberOfFields)
    }
    
    mutating func fieldOffsets() -> [Int] {
        return pointer.pointee.typeDescriptor.pointee
            .offsetToTheFieldOffsetVector
            .vector(metadata: pointer.raw.assumingMemoryBound(to: Int.self), n: numberOfFields())
            .map(numericCast)
    }

    mutating func methods() -> [MethodInfo] {
        return vtable.compactMap { functionPointer in
            var symbolInfo = Dl_info()
            dladdr(functionPointer, &symbolInfo)
            guard let name = symbolInfo.dli_sname else { return nil }

            let mangled = String(cString: name)
            guard let demangled = try? parseMangledSwiftSymbol(mangled) else { return nil }

            guard let module = demangled.module, !unsupportedModules.contains(module) else {
                return nil
            }

            guard !demangled.isInit else { return nil }

            // This is still wrong. But it appears to conform to a similar layout as the FunctionMetadataLayout
            let functionBasePointer = symbolInfo.dli_fbase.assumingMemoryBound(to: FunctionMetadataLayout.self)
            let functionInfo = FunctionMetadata(pointer: functionBasePointer).info()

            let arguments = zip(demangled.labelList ?? [], functionInfo.argumentTypes)
                .map { MethodInfo.Argument(name: $0.0, type: $0.1) }

            return MethodInfo(methodName: demangled.methodName ?? demangled.description,
                              symbol: demangled,
                              manngledName: mangled,
                              arguments: arguments,
                              functionInfo: functionInfo)
        }
    }
    
    mutating func properties() -> [PropertyInfo] {
        let offsets = fieldOffsets()
        let fieldDescriptor = pointer.pointee.typeDescriptor.pointee
            .fieldDescriptor
            .advanced()
        
        let genericVector = genericArgumentVector()

        return (0..<numberOfFields()).map { i in
            let record = fieldDescriptor
                .pointee
                .fields
                .element(at: i)
            
            return PropertyInfo(
                name: record.pointee.fieldName(),
                type: record.pointee.type(
                    genericContext: pointer.pointee.typeDescriptor,
                    genericArguments: genericVector
                ),
                isVar: record.pointee.isVar,
                offset: offsets[i],
                ownerType: type
            )
        }
    }
    
    func genericArguments() -> UnsafeMutableBufferPointer<Any.Type> {
        guard isGeneric else { return .init(start: nil, count: 0) }
        let count = genericContextHeader.base.numberOfParams
        return genericArgumentVector().buffer(n: Int(count))
    }
    
    func genericArgumentVector() -> UnsafeMutablePointer<Any.Type> {
        return pointer
            .advanced(by: genericArgumentOffset, wordSize: MemoryLayout<UnsafeRawPointer>.size)
            .assumingMemoryBound(to: Any.Type.self)
    }
    
    /// Retreives a trailing object from the `typeDescriptor`
    /// The offset is in the bytes from the end of the object.
    func getTypeDescTrailingObject<T>(at offset: Int, as: T.Type) -> T {
        return pointer.pointee.typeDescriptor.advanced(by: 1)
            .raw.advanced(by: offset)
            .assumingMemoryBound(to: T.self)
            .pointee
    }
}

extension SwiftSymbol {

    var module: String? {
        if kind == .module {
            return description
        }

        return children.first { $0.module }
    }

    var methodName: String? {
        switch kind {
        case .global, .extension:
            return children.first { $0.methodName }
        case .function:
            return children.first { child in
                guard case .identifier = child.kind else { return nil }
                return child.description
            }
        default:
            return nil
        }
    }

    var labelList: [String?]? {
        if kind == .labelList {
            return children.map { child in
                switch child.contents {
                case .none, .index:
                    return nil
                case .name(let name):
                    return name
                }
            }
        }

        return children.first { $0.labelList }
    }

    var isInit: Bool {
        switch kind {
        case .global, .extension:
            return children.allSatisfy { $0.isInit }
        case .allocator, .constructor:
            return true
        default:
            return false
        }
    }

}

extension Sequence {

    func first<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let result = try transform(element) {
                return result
            }
        }
        return nil
    }

}
