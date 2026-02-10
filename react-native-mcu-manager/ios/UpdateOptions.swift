import ExpoModulesCore

struct UpdateOptions: Record {
    @Field var eraseAppSettings: Bool = false
    @Field var estimatedSwapTime: TimeInterval = 0
    @Field var mcubootBufferCount: Int = 1
    @Field var upgradeFileType: Int = 0
    @Field var upgradeMode: Int?
}
