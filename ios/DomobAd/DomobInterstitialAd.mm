#import "DomobInterstitialAd.h"
#import "DMInterstitialAdController.h"

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "CCLuaBridge.h"

using namespace cocos2d;

@implementation DomobInterstitialAd

static DomobInterstitialAd *s_sharedInstance = nil;

// ObjC interface

+ (DomobInterstitialAd *) sharedInstance
{
    if (!s_sharedInstance)
    {
        s_sharedInstance = [[DomobInterstitialAd alloc] init];
    }
    return s_sharedInstance;
}

+ (void) purgeSharedInstance
{
    if (s_sharedInstance)
    {
        [s_sharedInstance release];
        s_sharedInstance = nil;
    }
}

- (id) init
{
    self = [super init];
    if (self)
    {
        dmInterstitial_ = nil;
        rootViewController_ = nil;
        scriptHandler_ = 0;
        notificationEnabled_ = NO;
    }
    return self;
}

- (void) dealloc
{
    dmInterstitial_.delegate = nil;
    [dmInterstitial_ release];
    [rootViewController_ release];
    
    [super dealloc];
}

- (void) setViewController:(UIViewController *)controller
{
    rootViewController_ = controller;
    [rootViewController_ retain];
}


// lua interface

// 初始化插屏广告
+ (void) startup:(NSDictionary *)dict
{
    NSString *appKey      = [dict objectForKey:@"appKey"];
    NSString *placementId = [dict objectForKey:@"placementId"];
    if (!appKey || !placementId)
    {
        NSLog(@"DomobInterstitialAd:startup() - invalid appKey or placementId");
        return;
    }
    [[DomobInterstitialAd sharedInstance] startup:appKey placementId:placementId];
}

+ (void) showAd
{
    [[DomobInterstitialAd sharedInstance] showAd];
}

+ (void) registerScriptHandler:(NSDictionary *)dict
{
    NSNumber *scriptHandler_ = [dict objectForKey:@"listener"];
    if (!scriptHandler_)
    {
        return;
    }
    
    int scriptHandler = [scriptHandler_ intValue];
    [[DomobInterstitialAd sharedInstance] registerScriptHandler:scriptHandler];
}

+ (void) unregisterScriptHandler
{
    [[DomobInterstitialAd sharedInstance] unregisterScriptHandler];
}

// instance methods
- (void) startup:(NSString *)appKey placementId:(NSString *)placementId
{
    CGSize adSize;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        adSize = DOMOB_AD_SIZE_300x250;
    }
    else
    {
        adSize = DOMOB_AD_SIZE_600x500;
    }
    
    dmInterstitial_ = [[DMInterstitialAdController alloc] initWithPublisherId:appKey
                                                                  placementId:placementId
                                                           rootViewController:rootViewController_
                                                                         size:adSize];
    
    dmInterstitial_.delegate = self;
    [dmInterstitial_ loadAd];
}

- (void) showAd
{
    // 在需要呈现插屏广告前，先通过isReady方法检查广告是否就绪
    if (dmInterstitial_.isReady)
    {
        // 呈现插屏广告
        [dmInterstitial_ present];
    }
    else
    {
        // 如果还没有ready，可以再调用loadAd
        [dmInterstitial_ loadAd];
    }
}

- (void) registerScriptHandler:(int)scriptHandler
{
    [self unregisterScriptHandler];
    scriptHandler_ = scriptHandler;
}

- (void) unregisterScriptHandler
{
    if (scriptHandler_)
    {
        CCLuaBridge::releaseLuaFunctionById(scriptHandler_);
        scriptHandler_ = 0;
    }
}


#pragma mark -
#pragma mark DMInterstitialAdController Delegate

// 当插屏广告被成功加载后，回调该方法
- (void)dmInterstitialSuccessToLoadAd:(DMInterstitialAdController *)dmInterstitial
{
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_LOAD_SUCCESS");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_LOAD_AD_SUCCESS");
    NSLog(@"[Domob Interstitial] success to load ad.");
}

// 当插屏广告加载失败后，回调该方法
- (void)dmInterstitialFailToLoadAd:(DMInterstitialAdController *)dmInterstitial withError:(NSError *)err
{
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_LOAD_FAILED");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_LOAD_FAILED");
    NSLog(@"[Domob Interstitial] fail to load ad. %@", err);
}

// 当插屏广告要被呈现出来前，回调该方法
- (void)dmInterstitialWillPresentScreen:(DMInterstitialAdController *)dmInterstitial
{
    NSLog(@"[Domob Interstitial] success to open.");
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_OPEN");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_OPENE");
}

// 当插屏广告被关闭后，回调该方法
- (void)dmInterstitialDidDismissScreen:(DMInterstitialAdController *)dmInterstitial
{
    NSLog(@"[Domob Interstitial] success to close.");
    // 插屏广告关闭后，加载一条新广告用于下次呈现
    [dmInterstitial_ loadAd];
    
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_CLOSE");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_CLOSE");
}

// 当将要呈现出 Modal View 时，回调该方法。如打开内置浏览器。
- (void)dmInterstitialWillPresentModalView:(DMInterstitialAdController *)dmInterstitial
{
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_MODAL_OPEN");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_MODAL_OPEN");
}

// 当呈现的 Modal View 被关闭后，回调该方法。如内置浏览器被关闭。
- (void)dmInterstitialDidDismissModalView:(DMInterstitialAdController *)dmInterstitial
{
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_MODAL_CLOSE");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_MODAL_CLOSE");
}

// 当因用户的操作（如点击下载类广告，需要跳转到Store），需要离开当前应用时，回调该方法
- (void)dmInterstitialApplicationWillEnterBackground:(DMInterstitialAdController *)dmInterstitial
{
    NSLog(@"[Domob Interstitial] success to Background.");
    if (scriptHandler_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandler_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("DOMOB_INTERSTITIAL_LEAVE");
        stack->executeFunction(1);
    }
    CCNotificationCenter::sharedNotificationCenter()->postNotification("DOMOB_INTERSTITIAL_LEAVE");
}

@end
