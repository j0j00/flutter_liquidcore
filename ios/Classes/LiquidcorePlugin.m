#import "LiquidcorePlugin.h"
#import <flutter_liquidcore/flutter_liquidcore-Swift.h>

@implementation LiquidcorePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftLiquidcorePlugin registerWithRegistrar:registrar];
}
@end
