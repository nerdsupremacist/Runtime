
import Foundation

public struct MethodInfo {
    public struct Argument {
        public var name: String?
        public var type: Any.Type
    }

    public var name: String
    public var arguments: [Argument]
    public var selector: Selector
    public var functionInfo: FunctionInfo
}
