
import Foundation
import CwlDemangle
import CRuntime

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

    var baseAddress: UnsafeRawPointer
    var address: UnsafeRawPointer
    
    public func call(receiver: Any, arguments: [Any]) throws -> Any {
        assert(arguments.count == self.arguments.count, "Argument count must correspond to original argument count")

        let types = self.arguments.map { $0.type } + [returnType]
        let sizes = try types
            .map { try metadata(of: $0) }
            .map { $0.size }

        let size = sizes.reduce(0, +)
        let argumentPointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)

        var offset = 0
        for (value, size) in zip(arguments + [receiver], sizes) {
            let pointer = withUnsafePointer(to: value) { $0.raw }
            argumentPointer.advanced(by: offset).copyMemory(from: pointer, byteCount: size)
            offset += size
        }

        let value = callFunction(UnsafeMutableRawPointer(mutating: address), argumentPointer, Int32(size))
        return unsafeBitCast(value, to: Any.self)
    }
}

private func casted<T>(value: Any, to type: T.Type = T.self) -> Any {
    return withUnsafePointer(to: value) { $0.raw.assumingMemoryBound(to: type).pointee }
}
