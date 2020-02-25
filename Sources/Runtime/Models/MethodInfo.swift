
import Foundation
import CwlDemangle

public struct MethodInfo {
    public struct Argument {
        public var name: String?
        public var type: Any.Type
    }

    public var methodName: String
    public var symbol: SwiftSymbol
    public var manngledName: String
    public var arguments: [Argument]
    public var returnType: Any.Type
    var address: UnsafeRawPointer

    public func call(receiver: Any, arguments: [Any]) -> Any {
        assert(arguments.count == self.arguments.count, "Argument count must correspond to original argument count")
        switch arguments.count {
        case 0:
            let function = unsafeBitCast(address, to: (@convention(c) (Any) -> Any).self)
            return function(receiver)
        case 1:
            let function = unsafeBitCast(address, to: (@convention(c) (Any, Any) -> Any).self)
            return function(arguments[0], receiver)
        case 2:
            let function = unsafeBitCast(address, to: (@convention(c) (Any, Any, Any) -> Any).self)
            return function(arguments[0], arguments[1], receiver)
        case 3:
            let function = unsafeBitCast(address, to: (@convention(c) (Any, Any, Any, Any) -> Any).self)
            return function(arguments[0], arguments[1], arguments[2], receiver)
        case 4:
            let function = unsafeBitCast(address, to: (@convention(c) (Any, Any, Any, Any, Any) -> Any).self)
            return function(arguments[0], arguments[1], arguments[2], arguments[3], receiver)
        case 5:
            let function = unsafeBitCast(address, to: (@convention(c) (Any, Any, Any, Any, Any, Any) -> Any).self)
            return function(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], receiver)

        default:
            fatalError()
        }
    }
}
