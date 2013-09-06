
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DMInterstitialAdController.h"

@interface DomobInterstitialAd : NSObject <DMInterstitialAdControllerDelegate> {
    DMInterstitialAdController *dmInterstitial_;
    UIViewController *rootViewController_;
    int scriptHandler_;
    BOOL notificationEnabled_;
}

// ObjC interface
+ (DomobInterstitialAd *) sharedInstance;
+ (void) purgeSharedInstance;
- (void) setViewController:(UIViewController *)controller;

// lua interface
+ (void) startup:(NSDictionary *)dict;
+ (void) showAd;
+ (void) registerScriptHandler:(NSDictionary *)dict;
+ (void) unregisterScriptHandler;

// instance methods
- (void) startup:(NSString *)appKey placementId:(NSString *)placementId;
- (void) showAd;
- (void) registerScriptHandler:(int)scriptHandler;
- (void) unregisterScriptHandler;

@end
