
import CwlDemangle

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
        case .getter, .setter:
            guard children.count == 1 else { return nil }
            return children[0].methodName.map { name in kind == .setter ? "set_\(name)" : name }
        case .function, .variable:
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

extension SwiftSymbol {

    var argumentTypes: [TypeSymbol] {
        guard let functionType = functionType else { return [] }

        switch functionType.kind {

        case .setter:
            guard functionType.children.count == 1 else { return [] }
            return functionType.children[0].typeSymbol.map { [$0] } ?? []

        case .getter:
            return []

        default:
            return functionType.children.first(where: { $0.kind == .argumentTuple })?.typeSymbol?.flatten ?? []

        }
    }

    var returnType: TypeSymbol? {
        guard let functionType = functionType else { return nil }

        switch functionType.kind {

        case .setter:
            return .tuple([])

        case .getter:
            guard functionType.children.count == 1 else { return nil }
            return functionType
                .children[0]
                .typeSymbol

        default:
            return functionType.children.first(where: { $0.kind == .returnType })?.typeSymbol

        }
    }

    private var functionType: SwiftSymbol? {
        switch kind {
        case .functionType, .getter, .setter:
            return self
        default:
            return children.first { $0.functionType }
        }
    }

    private var typeSymbol: TypeSymbol? {
        switch kind {
        case .protocolList, .typeList, .argumentTuple, .returnType, .tupleElement, .type, .existentialMetatype, .protocolList:
            guard children.count == 1 else { return nil }
            return children[0].typeSymbol
        case .tuple:
            let elements = children.compactMap { $0.typeSymbol }
            if elements.count == 1 {
                return elements[0]
            }
            return .tuple(elements)
        case .boundGenericStructure, .boundGenericEnum, .boundGenericClass:
            guard case .concrete(let descriptor) = children.first?.typeSymbol,
                let list = children.first(where: { $0.kind == .typeList }) else { return nil }

            let arguments = list.children.compactMap { $0.typeSymbol }
            guard !arguments.isEmpty else { return nil }
            return .generic(descriptor, arguments: arguments)
        case .structure, .enum, .protocol, .class:
            guard let descriptor = typeDescriptor else { return nil }
            return .concrete(descriptor)
        case .variable:
            return children.first { child in
                guard case .type = child.kind else { return nil }
                return child.typeSymbol
            }
        default:
            return nil
        }
    }

    private var typeDescriptor: TypeSymbol.Descriptor? {
        guard let kind = kind.descriptorKind,
            let module = children.first(where: { $0.kind == .module }),
            let name = children.first(where: { $0.kind == .identifier }) else { return nil }

        return TypeSymbol.Descriptor(module: module.description, name: name.description, kind: kind)
    }

}

extension SwiftSymbol.Kind {

    fileprivate var descriptorKind: TypeSymbol.Kind? {
        switch self {
        case .structure:
            return .struct
        case .enum:
            return .enum
        case .protocol:
            return .protocol
        case .class:
            return .class
        default:
            return nil
        }
    }

}
