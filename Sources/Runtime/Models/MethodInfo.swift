
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
}
