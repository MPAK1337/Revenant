#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C bridge for DeviceSpoofManager (Swift)
/// Provides access to spoofed device information from Objective-C code
@interface DeviceSpoofBridge : NSObject

/// Returns YES if device spoofing is enabled
+ (BOOL)isEnabled;

/// Returns the spoofed device model, or nil if spoofing is disabled or using
/// real device
+ (NSString *_Nullable)spoofedDeviceModel;

/// Returns the spoofed system version, or nil if spoofing is disabled or using
/// real device
+ (NSString *_Nullable)spoofedSystemVersion;

@end

NS_ASSUME_NONNULL_END
