
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
    
    public var address: UnsafeRawPointer
}

private func casted<T>(value: Any, to type: T.Type = T.self) -> Any {
    return withUnsafePointer(to: value) { $0.raw.assumingMemoryBound(to: type).pointee }
}
