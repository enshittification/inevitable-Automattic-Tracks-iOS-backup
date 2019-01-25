#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface TracksDeviceInformation : NSObject

@property (nonatomic, readonly) NSString *os;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSString *brand;
@property (nonatomic, readonly) NSString *model;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *appBuild;

// This information has the tendency to change
@property (nonatomic, readonly) NSString *deviceLanguage;
@property (nonatomic, readonly) NSString *currentNetworkOperator;
@property (nonatomic, readonly) NSString *currentNetworkRadioType;
@property (nonatomic, readonly) NSString *orientation;
@property (nonatomic, assign) BOOL isWiFiConnected;
@property (nonatomic, assign) BOOL isAppleWatchConnected;
@property (nonatomic, assign) BOOL isVoiceOverEnabled;
@property (nonatomic, assign) CGFloat statusBarHeight;

@end
