
#import <Foundation/Foundation.h>

/**
 
 event:
 
    showOffersWall
    closeOffersWall
    pointsGotted: points, pointsRemained
 
 */

@interface SDKYouMi : NSObject {
    int listener_;
}

// ObjC interface
+ (SDKYouMi*) sharedInstance;
+ (void) purgeSharedInstance;

// lua interface
+ (void) start:(NSDictionary*)dict;
+ (void) enablePointsWall;
+ (void) enablePointsManager;
+ (void) showOffers;
+ (int) getPointsRemained;
+ (void) spendPoints:(NSDictionary*)dict;
+ (void) addEventListener:(NSDictionary*)dict;
+ (void) removeEventListener;

@end
