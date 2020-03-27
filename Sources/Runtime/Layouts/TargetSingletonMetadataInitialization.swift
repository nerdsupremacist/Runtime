
import Foundation

struct TargetSingletonMetadataInitialization {
    let initializationCache: RelativePointer<Int32, Void>
    let incompleteMetadataOrResilientPattern: RelativePointer<Int32, Void>
    let completionFunction: RelativePointer<Int32, Void>
}

struct TargetForeignMetadataInitialization {
    let completionFunction: RelativePointer<Int32, Void>
}
