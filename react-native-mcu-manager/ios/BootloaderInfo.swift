import ExpoModulesCore

struct BootloaderInfo: Record {
    @Field var bootloader: String?
    @Field var mode: Int?
    @Field var noDowngrade: Bool?
}
