
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

extension SwiftSymbol {

    fileprivate var arguments: [TypeSymbol] {
        return functionType?.children.first(where: { $0.kind == .argumentTuple })?.types ?? []
    }

    fileprivate var returnType: TypeSymbol? {
        return nil
//        return functionType?.children.first(where: { $0.kind == .returnType })
    }

    private var functionType: SwiftSymbol? {
        if kind == .functionType {
            return self
        }

        return children.first { $0.functionType }
    }

    private var types: [TypeSymbol] {
        if kind == .structure {
            return [typeSymbol].compactMap { $0 }
        }

        return children.flatMap { $0.types }
    }

    private var typeSymbol: TypeSymbol? {
        return nil
//        switch kind {
//        case .type:
//
//        default:
//
//        }
//        guard case .structure = kind,
//            let module = children.first(where: { $0.kind == .module }),
//            let name = children.first(where: { $0.kind == .identifier }) else { return nil }
//
//        return TypeSymbol(module: module.description, name: name.description)
    }

}
