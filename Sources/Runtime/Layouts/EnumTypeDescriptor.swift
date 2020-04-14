//
//  EnumTypeDescriptor.swift
//  Runtime
//
//  Created by Wes Wickwire on 4/6/19.
//

struct EnumTypeDescriptor: TypeDescriptor {
    var flags: ContextDescriptorFlags
    var parent: RelativePointer<Int32, UnsafeRawPointer>
    var mangledName: RelativePointer<Int32, CChar>
    var accessFunctionPointer: RelativePointer<Int32, UnsafeRawPointer>
    var fieldDescriptor: RelativePointer<Int32, FieldDescriptor>
    var numPayloadCasesAndPayloadSizeOffset: UInt32
    var numberOfFields: Int32 // numEmptyCases
    var offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, Int32>
}

extension EnumTypeDescriptor {

    var numberOfPayloadCases: Int {
        return Int(numPayloadCasesAndPayloadSizeOffset.value(at: 8, width: 24))
    }

    var payloadSizeOffset: RelativePointer<UInt8, UnsafeRawPointer> {
        return RelativePointer(offset: UInt8(numPayloadCasesAndPayloadSizeOffset.value(at: 0, width: 8)))
    }

}

extension UInt32 {

    func value(at position: Int, width: Int) -> UInt32 {
        let shift = Self(MemoryLayout<UInt32>.size * 8 - position - width)
        let shape = UInt32.max >> (MemoryLayout<UInt32>.size * 8 - width)
        return (self >> shift) & shape
    }

}
