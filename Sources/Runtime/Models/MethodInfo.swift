
import Foundation
import CwlDemangle

private typealias ArgumentVector = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

public struct MethodInfo {
    public struct Argument {
        public var name: String?
        public var type: Any.Type
    }

    public var receiverType: Any.Type
    public var methodName: String
    public var symbol: SwiftSymbol
    public var manngledName: String
    public var arguments: [Argument]
    public var returnType: Any.Type
    var address: UnsafeRawPointer


    public func call(receiver: Any, arguments: [Any]) throws -> Any {
        assert(arguments.count == self.arguments.count, "Argument count must correspond to original argument count")

        let types = self.arguments.map { $0.type } + [receiverType]
        let metadata = try types.map { try typeInfo(of: $0) }
        let sizes = metadata.map { $0.size }

        let size = sizes.reduce(0, +)
        assert(size <= 128, "Arguments take up too much space. We didn't plan for that... ¯\\_(ツ)_/¯")
        let offsets = [128 - size] + sizes.dropLast().zipWithNext { $0 + $1 }

        let pointer = UnsafeMutableRawPointer.allocate(byteCount: 128, alignment: 0)
        let data = arguments + [receiver]

        zip(data, zip(sizes, offsets)).forEach { item, typeInfo in
            let (size, offset) = typeInfo
            var item = item
            let itemPointer = withUnsafeBytes(of: &item) { $0.baseAddress! }
            pointer.advanced(by: offset).copyMemory(from: itemPointer, byteCount: size)
        }

        let function = unsafeBitCast(address, to: (@convention(thin) (ArgumentVector) -> Any).self)
        return function(pointer.assumingMemoryBound(to: ArgumentVector.self).pointee)
    }
}

extension Collection {

    func zipWithNext(_ transform: (Element, Element) throws -> Element) rethrows -> [Element] {
        var array = [Element]()
        var last: Element?
        for element in self {
            let value = try last.map { try transform($0, element) } ?? element
            array.append(value)
            last = value
        }
        return array
    }

}
