
import Foundation
import CwlDemangle
import CRuntime

public class MethodInfo {
    public struct Argument {
        public var name: String?
        public var type: Any.Type
        public var defaultAddress: UnsafeRawPointer?
    }

    public var receiverType: Any.Type
    public var methodName: String
    public var symbol: SwiftSymbol
    public var manngledName: String
    public var arguments: [Argument]
    public var returnType: Any.Type
    
    public var address: UnsafeRawPointer

    init(receiverType: Any.Type,
         methodName: String,
         symbol: SwiftSymbol,
         manngledName: String,
         arguments: [Argument],
         returnType: Any.Type,
         address: UnsafeRawPointer) {

        self.receiverType = receiverType
        self.methodName = methodName
        self.symbol = symbol
        self.manngledName = manngledName
        self.arguments = arguments
        self.returnType = returnType
        self.address = address
    }
}

private func casted<T>(value: Any, to type: T.Type = T.self) -> Any {
    return withUnsafePointer(to: value) { $0.raw.assumingMemoryBound(to: type).pointee }
}
