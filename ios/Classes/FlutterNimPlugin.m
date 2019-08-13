#import "FlutterNimPlugin.h"
#import <flutter_nim/flutter_nim-Swift.h>

@implementation FlutterNimPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterNIMPlugin registerWithRegistrar:registrar];
}
@end
