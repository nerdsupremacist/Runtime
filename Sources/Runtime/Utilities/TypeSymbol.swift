
import Foundation

indirect enum TypeSymbol {
    struct Descriptor {
        let module: String
        let name: String
    }

    case concrete(Descriptor)
    case generic(Descriptor, arguments: [TypeSymbol])
    case tuple([TypeSymbol])
}

extension TypeSymbol {

    var flatten: [TypeSymbol] {
        switch self {
        case .concrete, .generic:
            return [self]
        case .tuple(let elements):
            return elements.flatMap { $0.flatten }
        }
    }

}

}
