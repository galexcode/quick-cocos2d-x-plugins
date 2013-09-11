
#import "SDKYouMi.h"
#import "YouMiConfig.h"
#import "YouMiWall.h"
#import "YouMiWallAppModel.h"
#import "YouMiPointsManager.h"

#include "CCLuaValue.h"
#include "CCLuaBridge.h"

using namespace cocos2d;

@implementation SDKYouMi

static SDKYouMi *s_sharedInstance = NULL;

// ObjC interface
+ (SDKYouMi*) sharedInstance
{
    if (!s_sharedInstance)
    {
        [s_sharedInstance = [SDKYouMi alloc] init];
    }
    return s_sharedInstance;
}

+ (void) purgeSharedInstance
{
    if (s_sharedInstance)
    {
        [s_sharedInstance release];
        s_sharedInstance = NULL;
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObject:self];
    [super dealloc];
}

// lua interface
+ (void) start:(NSDictionary*)dict
{
    NSString *appId = [dict objectForKey:@"appId"];
    NSString *appSecret = [dict objectForKey:@"appSecret"];
    NSNumber *useInAppStore = [dict objectForKey:@"useInAppStore"];
    NSString *userId = [dict objectForKey:@"userId"];

    if (!appId || !appSecret)
    {
        NSLog(@"SDKYouMi start() - Invalid appId \"%@\" or appSecret \"%@\"", appId, appSecret);
        return;
    }

    [[SDKYouMi sharedInstance] start:appId
                           appSecret:appSecret
                       useInAppStore:useInAppStore ? [useInAppStore boolValue] : NO
                              userId:userId];
}

+ (void) enablePointsWall
{
    [YouMiWall enable];
}

+ (void) enablePointsManager
{
    [YouMiPointsManager enable];
}

+ (void) showOffers
{

    [YouMiWall showOffers:YES didShowBlock:^{
        int listener = [[SDKYouMi sharedInstance] getEventListenerHandler];
        if (listener)
        {
            CCLuaValueDict event;
            event["name"] = CCLuaValue::stringValue("showOffersWall");
            CCLuaBridge::pushLuaFunctionById(listener);
            CCLuaBridge::getStack()->pushCCLuaValueDict(event);
            CCLuaBridge::getStack()->executeFunction(1);
        }
        NSLog(@"有米积分墙已显示");
    } didDismissBlock:^{
        int listener = [[SDKYouMi sharedInstance] getEventListenerHandler];
        if (listener)
        {
            CCLuaValueDict event;
            event["name"] = CCLuaValue::stringValue("closeOffersWall");
            CCLuaBridge::pushLuaFunctionById(listener);
            CCLuaBridge::getStack()->pushCCLuaValueDict(event);
            CCLuaBridge::getStack()->executeFunction(1);
        }
        NSLog(@"有米积分墙已退出");
    }];
}

+ (int) getPointsRemained
{
    return [YouMiPointsManager pointsRemained];
}

+ (void) spendPoints:(NSDictionary *)dict
{
    NSNumber *points_ = [dict objectForKey:@"listener"];
    int points = points_ ? [points_ intValue] : 0;
    if (points > 0)
    {
        [YouMiPointsManager spendPoints:points];
    }
}

+ (void) addEventListener:(NSDictionary*)dict
{
    NSNumber *listener_ = [dict objectForKey:@"listener"];
    int listener = listener_ ? [listener_ intValue] : 0;
    if (listener)
    {
        [[SDKYouMi sharedInstance] addEventListener:listener];
    }
}

+ (void) removeEventListener
{
    [[SDKYouMi sharedInstance] removeEventListener];
}


// instance methods
- (void) start:(NSString*)appId appSecret:(NSString*)appSecret useInAppStore:(BOOL)useInAppStore userId:(NSString*)userId
{
    // 可选，详细请看YouMiSDK常见问题解答
    [YouMiConfig setUseInAppStore:useInAppStore];

    if (userId)
    {
        // 可选 (用于帮助开发者区分用户，例如应用有不同账号登陆，可以把账号名设置为userID，如果不设置，则返回积分时userID字段为"")
        [YouMiConfig setUserID:userId];
    }

    [YouMiConfig launchWithAppID:appId appSecret:appSecret];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pointsGotted:)
                                                 name:kYouMiPointsManagerRecivedPointsNotification
                                               object:nil];
}

- (void) addEventListener:(int)listener
{
    [self removeEventListener];
    listener_ = listener;
    CCLuaBridge::retainLuaFunctionById(listener_);
}

- (void) removeEventListener
{
    if (listener_)
    {
        CCLuaBridge::releaseLuaFunctionById(listener_);
        listener_ = 0;
    }
}

- (int) getEventListenerHandler
{
    return listener_;
}

- (void) pointsGotted:(NSNotification*)notification
{
    NSDictionary *dict = [notification userInfo];
    NSNumber *freshPoints = [dict objectForKey:kYouMiPointsManagerFreshPointsKey];

    // 这里的积分不应该拿来使用, 只是用于告知一下用户, 可以通过 [YouMiPointsManager spendPoints:]来使用积分
    CCLuaValueDict event;
    int listener = [[SDKYouMi sharedInstance] getEventListenerHandler];
    if (listener)
    {
        event["name"] = CCLuaValue::stringValue("pointsGotted");
        event["points"] = CCLuaValue::intValue([freshPoints intValue]);
        event["pointsRemained"] = CCLuaValue::intValue([SDKYouMi getPointsRemained]);
        CCLuaBridge::pushLuaFunctionById(listener);
        CCLuaBridge::getStack()->pushCCLuaValueDict(event);
        CCLuaBridge::getStack()->executeFunction(1);
    }
}

@end
