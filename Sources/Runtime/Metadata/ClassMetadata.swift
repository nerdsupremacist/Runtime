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
import CSymbols

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

struct AnyClassMetadata {
    
    var pointer: UnsafeMutablePointer<AnyClassMetadataLayout>
    
    init(type: Any.Type) {
        pointer = unsafeBitCast(type, to: UnsafeMutablePointer<AnyClassMetadataLayout>.self)
    }
    
    func asClassMetadata() -> ClassMetadata? {
        guard pointer.pointee.isSwiftClass else {
            return nil
        }
        let ptr = pointer.raw.assumingMemoryBound(to: ClassMetadataLayout.self)
        return ClassMetadata(pointer: ptr)
    }
}

struct ClassMetadata: NominalMetadataType {
    
    var pointer: UnsafeMutablePointer<ClassMetadataLayout>
    
    var hasResilientSuperclass: Bool {
        let typeDescriptor = pointer.pointee.typeDescriptor
        return ((typeDescriptor.pointee.flags >> 16) & 0x2000) != 0
    }
    
    var areImmediateMembersNegative: Bool {
        let typeDescriptor = pointer.pointee.typeDescriptor
        return ((typeDescriptor.pointee.flags >> 16) & 0x1000) != 0
    }
    
    var genericArgumentOffset: Int {
        let typeDescriptor = pointer.pointee.typeDescriptor
        
        if !hasResilientSuperclass {
            return areImmediateMembersNegative
                ? -Int(typeDescriptor.pointee.negativeSizeAndBoundsUnion.metadataNegativeSizeInWords)
                : Int(typeDescriptor.pointee.metadataPositiveSizeInWords - typeDescriptor.pointee.numImmediateMembers)
        }
        
        let storedBounds = typeDescriptor.pointee
            .negativeSizeAndBoundsUnion
            .resilientMetadataBounds()
            .pointee
            .advanced()
            .pointee
        
        return storedBounds.immediateMembersOffset / MemoryLayout<UnsafeRawPointer>.size
    }

    mutating func methods() -> [MethodInfo] {
        return vtable.compactMap { functionPointer in
            var symbolInfo = SymbolInfo(name: nil, address: nil)
            loadSymbol(functionPointer, &symbolInfo)
            guard let name = symbolInfo.name else { return nil }

            let mangled = String(cString: name)
            guard let demangled = try? parseMangledSwiftSymbol(mangled) else { return nil }

            guard let module = demangled.module, !unsupportedModules.contains(module) else { return nil }

            guard !demangled.isInit else { return nil }

            let argumentTypes = demangled.argumentTypes.map { $0.type() }
            let returnType = demangled.returnType?.type() ?? Any.self

            let arguments = zip(demangled.labelList ?? [], argumentTypes)
                .enumerated()
                .map { value -> MethodInfo.Argument in
                    let symbolName = value.offset == 0 ? "\(mangled)fA_" : "\(mangled)fA\(value.offset - 1)_"
                    let cString = symbolName.cString(using: .ascii)!
                    let symbolPointer = loadAddressForSymbol(cString)
                    return MethodInfo.Argument(name: value.element.0, type: value.element.1, defaultAddress: symbolPointer)
                }

            return MethodInfo(receiverType: type,
                              methodName: demangled.methodName ?? demangled.description,
                              symbol: demangled,
                              manngledName: mangled,
                              arguments: arguments,
                              returnType: returnType,
                              address: symbolInfo.address)
        }
    }


    func superClassMetadata() -> AnyClassMetadata? {
        let superClass = pointer.pointee.superClass
        guard superClass != swiftObject() else {
            return nil
        }
        return AnyClassMetadata(type: superClass)
    }
    
    mutating func toTypeInfo() -> TypeInfo {
        var info = TypeInfo(metadata: self)
        info.mangledName = mangledName()
        info.properties = properties()
        info.methods = methods()
        info.genericTypes = Array(genericArguments())
        
        var superClass = superClassMetadata()?.asClassMetadata()
        while var sc = superClass {
            info.inheritance.append(sc.type)
            let superInfo = sc.toTypeInfo()
            info.properties.append(contentsOf: superInfo.properties)
            info.methods.append(contentsOf: superInfo.methods)
            superClass = sc.superClassMetadata()?.asClassMetadata()
        }
        
        return info
    }
}

typealias Meth = @convention(c) (UnsafeRawPointer) -> Void

struct TargetMethodDescriptor {
    var flags: UInt
    var impl: RelativePointer<Int, Meth>
    
    var kind: Kind {
        return Kind(rawValue: flags & 0x0F)!
    }
    
    var isInstance: Bool {
        return flags & 0x10 != 0
    }
    
    var isDynamic: Bool {
        return flags & 0x20 != 0
    }
    
    enum Kind: UInt {
        case method
        case `init`
        case getter
        case setter
        case modifyCoroutine
        case readCoroutine
    }
}

struct TargetVTableDescriptorHeader {
    let vTableOffset: UInt32
    let vTableSive: UInt32
}
