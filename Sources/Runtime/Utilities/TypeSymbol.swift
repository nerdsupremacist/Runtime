
import Foundation
import CRuntime

indirect enum TypeSymbol {
    enum Kind {
        case `struct`
        case `class`
        case `protocol`
        case `enum`
    }

    struct Descriptor {
        indirect enum Parent {
            case module(String)
            case descriptor(Descriptor)
        }
        
        let parent: Parent
        let name: String
        let kind: Kind
    }

    case any
    case concrete(Descriptor)
    case generic(Descriptor, arguments: [TypeSymbol])
    case tuple([TypeSymbol])
}

extension TypeSymbol {

    var flatten: [TypeSymbol] {
        switch self {
        case .concrete, .generic, .any:
            return [self]
        case .tuple(let elements):
            return elements.flatMap { $0.flatten }
        }
    }

}

extension TypeSymbol {

    func type() -> Any.Type? {
        if case .tuple(let array) = self, array.isEmpty {
            return Void.self
        }
        return metatype(for: mangledName)
    }

    fileprivate var mangledName: String {
        switch self {
        case .any:
            return "yp"
        case .concrete(let descriptor):
            return descriptor.mangledName
        case .generic(let descriptor, let arguments):
            let arguments = arguments.map { $0.mangledName }
            // TODO: this probably is still wrong
            return "\(descriptor.mangledName)y\(arguments.joined())G"
        case .tuple(let symbols):
            let symbols = symbols.map { $0.mangledName }
            return "T\(symbols.joined())"
        }
    }

}

extension TypeSymbol.Descriptor {

    fileprivate var mangledName: String {
        let postfix: String

        switch kind {
        case .class:
            postfix = "C"
        case .struct:
            postfix = "V"
        case .protocol:
            postfix = "_p"
        case .enum:
            postfix = "O"
        }
        
        switch parent {
        case .module("Swift"):
            let mangledName: String

            switch name {
            case "Array": mangledName = "a"
            case "AutoreleasingUnsafeMutablePointer": mangledName = "A"
            case "Bool": mangledName = "b"
            case "UnicodeScalar": mangledName = "c"
            case "Dictionary": mangledName = "D"
            case "Double": mangledName = "d"
            case "Float": mangledName = "f"
            case "Set": mangledName = "h"
            case "DefaultIndices": mangledName = "I"
            case "Int": mangledName = "i"
            case "Character": mangledName = "J"
            case "ClosedRange": mangledName = "N"
            case "Range": mangledName = "n"
            case "ObjectIdentifier": mangledName = "O"
            case "UnsafeMutablePointer": mangledName = "p"
            case "UnsafePointer": mangledName = "P"
            case "UnsafeBufferPointer": mangledName = "R"
            case "UnsafeMutableBufferPointer": mangledName = "r"
            case "String": mangledName = "S"
            case "Substring": mangledName = "s"
            case "UInt": mangledName = "u"
            case "UnsafeMutableRawPointer": mangledName = "v"
            case "UnsafeRawPointer": mangledName = "V"
            case "UnsafeRawBufferPointer": mangledName = "W"
            case "UnsafeMutableRawBufferPointer": mangledName = "w"

            case "Optional": mangledName = "q"

            case "BinaryFloatingPoint": mangledName = "B"
            case "Encodable": mangledName = "E"
            case "Decodable": mangledName = "e"
            case "FloatingPoint": mangledName = "F"
            case "RandomNumberGenerator": mangledName = "G"
            case "Hashable": mangledName = "H"
            case "Numeric": mangledName = "j"
            case "BidirectionalCollection": mangledName = "K"
            case "RandomAccessCollection": mangledName = "k"
            case "Comparable": mangledName = "L"
            case "Collection": mangledName = "l"
            case "MutableCollection": mangledName = "M"
            case "RangeReplaceableCollection": mangledName = "m"
            case "Equatable": mangledName = "Q"
            case "Sequence": mangledName = "T"
            case "IteratorProtocol": mangledName = "t"
            case "UnsignedInteger": mangledName = "U"
            case "RangeExpression": mangledName = "X"
            case "Strideable": mangledName = "x"
            case "RawRepresentable": mangledName = "Y"
            case "StringProtocol": mangledName = "y"
            case "SignedInteger": mangledName = "Z"
            case "BinaryInteger": mangledName = "z"

            default:
                switch kind {
                    // are there any other cases?
                case .class:
                    return "s\(name.count)\(name)\(postfix)"
                default:
                    return "s\(name.count)\(name)S"
                }
            }

            return "S\(mangledName)"
            
        case .module(let module):
            return "\(module.count)\(module)\(name.count)\(name)\(postfix)"
            
        case .descriptor(let descriptor):
            return "\(descriptor.mangledName)\(name.count)\(name)\(postfix)"
        }

        
    }

}

private func metatype(for mangled: String) -> Any.Type? {
    return mangled
        .cString(using: .utf8)!
        .withUnsafeBytes { pointer -> UnsafeRawPointer? in
            let casted = pointer.baseAddress!.assumingMemoryBound(to: Int8.self)
            return swift_getTypeByMangledNameInContext(casted,
                                                       Int32(mangled.count),
                                                       nil,
                                                       nil)
        }
        .map { unsafeBitCast($0, to: Any.Type.self) }
}
