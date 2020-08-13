#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE(McuManager, RNMcuManager, NSObject)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXTERN_METHOD(
    updateDevice:
    String
    updateFileUriString: String
    resolver:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject
)

@end
