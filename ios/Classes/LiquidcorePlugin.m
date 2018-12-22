#import "LiquidcorePlugin.h"
#import <liquidcore/liquidcore-Swift.h>

@implementation LiquidcorePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLiquidcorePlugin registerWithRegistrar:registrar];
}
@end
