#import "DeviceSpoofBridge.h"

// Access to UserDefaults to get spoofing settings
// This mirrors DeviceSpoofManager logic but in pure Objective-C
// to avoid Swift/ObjC bridging complexities in MtProtoKit

static NSString *const kDeviceSpoofIsEnabled = @"DeviceSpoof.isEnabled";
static NSString *const kDeviceSpoofHasExplicitConfiguration =
    @"DeviceSpoof.hasExplicitConfiguration";
static NSString *const kDeviceSpoofSelectedProfileId =
    @"DeviceSpoof.selectedProfileId";
static NSString *const kDeviceSpoofCustomDeviceModel =
    @"DeviceSpoof.customDeviceModel";
static NSString *const kDeviceSpoofCustomSystemVersion =
    @"DeviceSpoof.customSystemVersion";

static NSDictionary<NSNumber *, NSDictionary<NSString *, NSString *> *> *
DeviceSpoofProfiles(void) {
  static NSDictionary<NSNumber *, NSDictionary<NSString *, NSString *> *>
      *profiles;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    profiles = @{
      @1 : @{
        @"deviceModel" : @"iPhone 14 Pro",
        @"systemVersion" : @"iOS 17.2"
      },
      @2 : @{
        @"deviceModel" : @"iPhone 15 Pro Max",
        @"systemVersion" : @"iOS 17.4"
      },
      @3 : @{
        @"deviceModel" : @"Samsung SM-S918B",
        @"systemVersion" : @"Android 14"
      },
      @4 : @{
        @"deviceModel" : @"Google Pixel 8 Pro",
        @"systemVersion" : @"Android 14"
      },
      @5 : @{
        @"deviceModel" : @"PC 64bit",
        @"systemVersion" : @"Windows 11"
      },
      @6 : @{
        @"deviceModel" : @"MacBook Pro",
        @"systemVersion" : @"macOS 14.3"
      },
      @7 : @{
        @"deviceModel" : @"Web",
        @"systemVersion" : @"Chrome 121"
      },
      @8 : @{
        @"deviceModel" : @"HUAWEI MNA-LX9",
        @"systemVersion" : @"HarmonyOS 4.0"
      },
      @9 : @{
        @"deviceModel" : @"Xiaomi 2311DRK48G",
        @"systemVersion" : @"Android 14"
      }
    };
  });
  return profiles;
}

static NSString *DeviceSpoofTrimmedString(NSString *value) {
  if (value == nil) {
    return @"";
  }
  return
      [value stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSInteger DeviceSpoofSanitizedProfileId(NSUserDefaults *defaults) {
  NSInteger profileId =
      [defaults integerForKey:kDeviceSpoofSelectedProfileId];
  if (profileId == 0 || profileId == 100 ||
      DeviceSpoofProfiles()[@(profileId)] != nil) {
    return profileId;
  }
  [defaults setInteger:0 forKey:kDeviceSpoofSelectedProfileId];
  return 0;
}

static BOOL DeviceSpoofIsEnabled(NSUserDefaults *defaults) {
  return [defaults boolForKey:kDeviceSpoofHasExplicitConfiguration] &&
         [defaults boolForKey:kDeviceSpoofIsEnabled];
}

static void DeviceSpoofResolveValues(NSUserDefaults *defaults,
                                     NSString *__autoreleasing *deviceModel,
                                     NSString *__autoreleasing *systemVersion) {
  *deviceModel = nil;
  *systemVersion = nil;

  if (!DeviceSpoofIsEnabled(defaults)) {
    return;
  }

  NSInteger profileId = DeviceSpoofSanitizedProfileId(defaults);
  if (profileId == 0) {
    return;
  }

  if (profileId == 100) {
    NSString *customDeviceModel =
        DeviceSpoofTrimmedString([defaults stringForKey:kDeviceSpoofCustomDeviceModel]);
    NSString *customSystemVersion =
        DeviceSpoofTrimmedString([defaults stringForKey:kDeviceSpoofCustomSystemVersion]);
    if (customDeviceModel.length == 0 || customSystemVersion.length == 0) {
      return;
    }
    *deviceModel = customDeviceModel;
    *systemVersion = customSystemVersion;
    return;
  }

  NSDictionary<NSString *, NSString *> *profile = DeviceSpoofProfiles()[@(profileId)];
  *deviceModel = profile[@"deviceModel"];
  *systemVersion = profile[@"systemVersion"];
}

@implementation DeviceSpoofBridge

+ (BOOL)isEnabled {
  return DeviceSpoofIsEnabled([NSUserDefaults standardUserDefaults]);
}

+ (NSString *)spoofedDeviceModel {
  NSString *deviceModel = nil;
  NSString *systemVersion = nil;
  DeviceSpoofResolveValues([NSUserDefaults standardUserDefaults], &deviceModel,
                           &systemVersion);
  return deviceModel;
}

+ (NSString *)spoofedSystemVersion {
  NSString *deviceModel = nil;
  NSString *systemVersion = nil;
  DeviceSpoofResolveValues([NSUserDefaults standardUserDefaults], &deviceModel,
                           &systemVersion);
  return systemVersion;
}

@end
