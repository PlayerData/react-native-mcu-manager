#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_REMAP_MODULE(McuManager, RNMcuManager, RCTEventEmitter)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXTERN_METHOD(
    supportedEvents
)

RCT_EXTERN_METHOD(
    updateDevice:
    String
    updateFileUriString: String
    updateOptions:(NSDictionary)updateOptions
    resolver:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject
)

RCT_EXTERN_METHOD(
    cancel
)

@end
