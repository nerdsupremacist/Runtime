
import Foundation

protocol FlagValue {
    static var position: Int { get }
    static var width: Int { get }
    init(from: ContextDescriptorFlags)
}

extension ContextDescriptorFlags {

    func readFlag<T: FlagValue>() -> T {
        let shift = UInt32(MemoryLayout<ContextDescriptorFlags>.size * 8 - T.position - T.width)
        let shape = UInt32.max >> (MemoryLayout<ContextDescriptorFlags>.size * 8 - T.width)
        let initializationValue = (UInt32(bitPattern: self) >> shift) & shape
        return T(from: ContextDescriptorFlags(initializationValue))
    }

}
