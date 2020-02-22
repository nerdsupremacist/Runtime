
import Foundation

indirect enum TypeSymbol {
    struct Descriptor {
        let module: String
        let name: String
    }

    case concrete(Descriptor)
    case generic(Descriptor, arguments: TypeSymbol)
}