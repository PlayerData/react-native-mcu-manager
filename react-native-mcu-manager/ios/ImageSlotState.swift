import ExpoModulesCore

struct ImageSlotState: Record {
    @Field var image: UInt64?
    @Field var slot: UInt64?
    @Field var version: String?
    @Field var hash: String?
    @Field var bootable: Bool?
    @Field var pending: Bool?
    @Field var confirmed: Bool?
    @Field var active: Bool?
    @Field var permanent: Bool?
}
