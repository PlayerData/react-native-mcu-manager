import ExpoModulesCore

struct BootloaderInfo: Record {
    @Field var bootloader: String?
    @Field var bufferCount: UInt64?
    @Field var bufferSize: UInt64?
    @Field var mode: Int?
    @Field var noDowngrade: Bool?
}
