#import <React/RCTBridgeModule.h>

@implementation RCT_EXTERN_REMAP_MODULE(McuManager, RNMcuManager, NSObject)

RCT_EXTERN_METHOD(
    updateDevice: (NSString)macAddress
    updateFileUriString: (NSString)updateFileUriString
    resolver: (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject
)

@end
