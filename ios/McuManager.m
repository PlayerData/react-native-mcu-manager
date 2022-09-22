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
                  eraseImage:
                  NSString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )

RCT_EXTERN_METHOD(
                  createUpgrade:
                  NSString
                  bleId: NSString
                  updateFileUriString: NSString
                  updateOptions: NSDictionary
                  )

RCT_EXTERN_METHOD(
                  runUpgrade:
                  NSString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )

RCT_EXTERN_METHOD(
                  cancelUpgrade:
                  NSString
                  )

RCT_EXTERN_METHOD(
                  destroyUpgrade:
                  NSString
                  )

@end
