
import Foundation

enum MetadataInitialization: ContextDescriptorFlags, FlagValue {
    static var position: Int {
        return 14
    }

    static var width: Int {
        return 2
    }

    init(from value: ContextDescriptorFlags) {
        self = MetadataInitialization(rawValue: value) ?? .none
    }

    case none
    case singleton
    case foreign
}
