import ExpoModulesCore

struct UpdateOptions: Record {
  @Field var estimatedSwapTime: TimeInterval = 0
  @Field var upgradeMode: Int?
}
