#include "levelplay_ads.h"

#import <LevelPlay.h>
#import <LPMAdSize.h>
#import <LPMBannerAdView.h>
#import <LPMBannerAdViewConfigBuilder.h>
#import <LPMInitRequestBuilder.h>
#import <LPMInterstitialAd.h>
#import <LPMInterstitialAdDelegate.h>
#import <LPMRewardedAd.h>
#import <LPMRewardedAdDelegate.h>
#import <UIKit/UIKit.h>

#include "core/object/class_db.h"
#include "core/variant/variant.h"

static NSString *to_ns_string(const String &p_value) {
	CharString utf8 = p_value.utf8();
	return [NSString stringWithUTF8String:utf8.get_data()];
}

static String to_godot_string(NSString *p_value) {
	if (p_value == nil) {
		return String();
	}
	return String::utf8([p_value UTF8String]);
}

static String error_message(NSError *p_error) {
	if (p_error == nil) {
		return "Unknown LevelPlay error.";
	}
	NSString *message = p_error.localizedDescription;
	if (message.length == 0) {
		message = p_error.description;
	}
	return to_godot_string(message);
}

static UIViewController *top_view_controller(UIViewController *p_controller) {
	if (p_controller == nil) {
		return nil;
	}
	if (p_controller.presentedViewController != nil) {
		return top_view_controller(p_controller.presentedViewController);
	}
	if ([p_controller isKindOfClass:[UINavigationController class]]) {
		return top_view_controller(((UINavigationController *)p_controller).visibleViewController);
	}
	if ([p_controller isKindOfClass:[UITabBarController class]]) {
		return top_view_controller(((UITabBarController *)p_controller).selectedViewController);
	}
	return p_controller;
}

static UIViewController *active_view_controller() {
	UIWindow *active_window = nil;
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (![scene isKindOfClass:[UIWindowScene class]]) {
			continue;
		}
		UIWindowScene *window_scene = (UIWindowScene *)scene;
		if (window_scene.activationState != UISceneActivationStateForegroundActive && active_window != nil) {
			continue;
		}
		for (UIWindow *window in window_scene.windows) {
			if (window.isKeyWindow) {
				active_window = window;
				break;
			}
			if (active_window == nil && !window.hidden) {
				active_window = window;
			}
		}
		if (active_window.isKeyWindow) {
			break;
		}
	}
	return top_view_controller(active_window.rootViewController);
}

@class GodotLevelPlayBridge;

@interface GodotLevelPlayRewardedDelegate : NSObject <LPMRewardedAdDelegate>
@property(nonatomic, weak) GodotLevelPlayBridge *bridge;
- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge;
@end

@interface GodotLevelPlayInterstitialDelegate : NSObject <LPMInterstitialAdDelegate>
@property(nonatomic, weak) GodotLevelPlayBridge *bridge;
- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge;
@end

@interface GodotLevelPlayBannerDelegate : NSObject <LPMBannerAdViewDelegate>
@property(nonatomic, weak) GodotLevelPlayBridge *bridge;
- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge;
@end

@interface GodotLevelPlayBridge : NSObject
@property(nonatomic, assign) LevelPlayAds *owner;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, assign) BOOL initializing;
@property(nonatomic, strong) LPMRewardedAd *rewardedAd;
@property(nonatomic, strong) LPMInterstitialAd *interstitialAd;
@property(nonatomic, strong) LPMBannerAdView *bannerAd;
@property(nonatomic, strong) LPMAdSize *bannerSize;
@property(nonatomic, strong) GodotLevelPlayRewardedDelegate *rewardedDelegate;
@property(nonatomic, strong) GodotLevelPlayInterstitialDelegate *interstitialDelegate;
@property(nonatomic, strong) GodotLevelPlayBannerDelegate *bannerDelegate;
@property(nonatomic, copy) NSString *bannerPlacement;

- (instancetype)initWithOwner:(LevelPlayAds *)owner;
- (void)initializeWithAppKey:(NSString *)appKey
          rewardedAdUnitId:(NSString *)rewardedAdUnitId
      interstitialAdUnitId:(NSString *)interstitialAdUnitId
            bannerAdUnitId:(NSString *)bannerAdUnitId
           enableTestSuite:(BOOL)enableTestSuite
           bannerPlacement:(NSString *)bannerPlacement;
- (void)loadRewarded;
- (void)showRewarded:(NSString *)placementName;
- (void)loadInterstitial;
- (void)showInterstitial:(NSString *)placementName;
- (void)showBanner;
- (void)hideBanner;
- (void)shutdown;
- (void)emitAdType:(NSString *)adType event:(NSString *)event message:(NSString *)message;
- (void)createAdObjectsWithRewardedId:(NSString *)rewardedAdUnitId
                      interstitialId:(NSString *)interstitialAdUnitId
                            bannerId:(NSString *)bannerAdUnitId;
@end

@implementation GodotLevelPlayRewardedDelegate

- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge {
	self = [super init];
	if (self != nil) {
		self.bridge = bridge;
	}
	return self;
}

- (void)didLoadAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"rewarded" event:@"loaded" message:@"Rewarded ad loaded."];
}

- (void)didFailToLoadAdWithAdUnitId:(NSString *)adUnitId error:(NSError *)error {
	[self.bridge emitAdType:@"rewarded" event:@"failed" message:error.localizedDescription ?: error.description];
}

- (void)didDisplayAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"rewarded" event:@"displayed" message:@"Rewarded ad displayed."];
}

- (void)didRewardAdWithAdInfo:(LPMAdInfo *)adInfo reward:(LPMReward *)reward {
	LevelPlayAds *owner = self.bridge.owner;
	if (owner != nullptr) {
		owner->emit_reward_earned(to_godot_string(reward.name), (int)reward.amount);
		owner->emit_ad_event("rewarded", "rewarded", "Reward received.");
	}
}

- (void)didFailToDisplayAdWithAdInfo:(LPMAdInfo *)adInfo error:(NSError *)error {
	[self.bridge emitAdType:@"rewarded" event:@"show_failed" message:error.localizedDescription ?: error.description];
}

- (void)didClickAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"rewarded" event:@"clicked" message:@"Rewarded ad clicked."];
}

- (void)didCloseAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"rewarded" event:@"closed" message:@"Rewarded ad closed."];
	[self.bridge.rewardedAd loadAd];
}

- (void)didChangeAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"rewarded" event:@"info_changed" message:@"Rewarded ad info changed."];
}

@end

@implementation GodotLevelPlayInterstitialDelegate

- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge {
	self = [super init];
	if (self != nil) {
		self.bridge = bridge;
	}
	return self;
}

- (void)didLoadAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"interstitial" event:@"loaded" message:@"Interstitial ad loaded."];
}

- (void)didFailToLoadAdWithAdUnitId:(NSString *)adUnitId error:(NSError *)error {
	[self.bridge emitAdType:@"interstitial" event:@"failed" message:error.localizedDescription ?: error.description];
}

- (void)didDisplayAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"interstitial" event:@"displayed" message:@"Interstitial ad displayed."];
}

- (void)didFailToDisplayAdWithAdInfo:(LPMAdInfo *)adInfo error:(NSError *)error {
	[self.bridge emitAdType:@"interstitial" event:@"show_failed" message:error.localizedDescription ?: error.description];
}

- (void)didClickAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"interstitial" event:@"clicked" message:@"Interstitial ad clicked."];
}

- (void)didCloseAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"interstitial" event:@"closed" message:@"Interstitial ad closed."];
	[self.bridge.interstitialAd loadAd];
}

- (void)didChangeAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"interstitial" event:@"info_changed" message:@"Interstitial ad info changed."];
}

@end

@implementation GodotLevelPlayBannerDelegate

- (instancetype)initWithBridge:(GodotLevelPlayBridge *)bridge {
	self = [super init];
	if (self != nil) {
		self.bridge = bridge;
	}
	return self;
}

- (void)didLoadAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"loaded" message:@"Banner ad loaded."];
}

- (void)didFailToLoadAdWithAdUnitId:(NSString *)adUnitId error:(NSError *)error {
	[self.bridge emitAdType:@"banner" event:@"failed" message:error.localizedDescription ?: error.description];
}

- (void)didClickAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"clicked" message:@"Banner ad clicked."];
}

- (void)didDisplayAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"displayed" message:@"Banner ad displayed."];
}

- (void)didFailToDisplayAdWithAdInfo:(LPMAdInfo *)adInfo error:(NSError *)error {
	[self.bridge emitAdType:@"banner" event:@"show_failed" message:error.localizedDescription ?: error.description];
}

- (void)didLeaveAppWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"left_application" message:@"Banner opened another application."];
}

- (void)didExpandAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"expanded" message:@"Banner expanded."];
}

- (void)didCollapseAdWithAdInfo:(LPMAdInfo *)adInfo {
	[self.bridge emitAdType:@"banner" event:@"collapsed" message:@"Banner collapsed."];
}

@end

@implementation GodotLevelPlayBridge

- (instancetype)initWithOwner:(LevelPlayAds *)owner {
	self = [super init];
	if (self != nil) {
		self.owner = owner;
		self.bannerPlacement = @"";
	}
	return self;
}

- (void)runOnMain:(dispatch_block_t)block {
	if ([NSThread isMainThread]) {
		block();
	} else {
		dispatch_async(dispatch_get_main_queue(), block);
	}
}

- (void)initializeWithAppKey:(NSString *)appKey
          rewardedAdUnitId:(NSString *)rewardedAdUnitId
      interstitialAdUnitId:(NSString *)interstitialAdUnitId
            bannerAdUnitId:(NSString *)bannerAdUnitId
           enableTestSuite:(BOOL)enableTestSuite
           bannerPlacement:(NSString *)bannerPlacement {
	[self runOnMain:^{
		if (self.initialized) {
			if (self.owner != nullptr) {
				self.owner->emit_sdk_initialized(true, "Unity LevelPlay is already initialized.");
			}
			return;
		}
		if (self.initializing) {
			if (self.owner != nullptr) {
				self.owner->emit_sdk_initialized(false, "Unity LevelPlay initialization is already in progress.");
			}
			return;
		}
		if (appKey.length == 0) {
			if (self.owner != nullptr) {
				self.owner->emit_sdk_initialized(false, "LevelPlay app key is empty.");
			}
			return;
		}

		self.initializing = YES;
		self.bannerPlacement = bannerPlacement ?: @"";
		if (enableTestSuite) {
			[LevelPlay setMetaDataWithKey:@"is_test_suite" value:@"enable"];
		}

		LPMInitRequestBuilder *builder = [[LPMInitRequestBuilder alloc] initWithAppKey:appKey];
		LPMInitRequest *request = [builder build];
		__weak GodotLevelPlayBridge *weakSelf = self;
		[LevelPlay initWithRequest:request completion:^(LPMConfiguration *configuration, NSError *error) {
			GodotLevelPlayBridge *strongSelf = weakSelf;
			if (strongSelf == nil) {
				return;
			}
			strongSelf.initializing = NO;
			if (error != nil) {
				strongSelf.initialized = NO;
				if (strongSelf.owner != nullptr) {
					strongSelf.owner->emit_sdk_initialized(false, error_message(error));
				}
				return;
			}

			strongSelf.initialized = YES;
			[strongSelf createAdObjectsWithRewardedId:rewardedAdUnitId
									 interstitialId:interstitialAdUnitId
									       bannerId:bannerAdUnitId];
			if (strongSelf.owner != nullptr) {
				strongSelf.owner->emit_sdk_initialized(true, "Unity LevelPlay initialization succeeded.");
			}
		}];
	}];
}

- (void)createAdObjectsWithRewardedId:(NSString *)rewardedAdUnitId
                      interstitialId:(NSString *)interstitialAdUnitId
                            bannerId:(NSString *)bannerAdUnitId {
	self.rewardedAd = nil;
	self.interstitialAd = nil;
	[self.bannerAd destroy];
	[self.bannerAd removeFromSuperview];
	self.bannerAd = nil;

	if (rewardedAdUnitId.length > 0) {
		self.rewardedDelegate = [[GodotLevelPlayRewardedDelegate alloc] initWithBridge:self];
		self.rewardedAd = [[LPMRewardedAd alloc] initWithAdUnitId:rewardedAdUnitId];
		[self.rewardedAd setDelegate:self.rewardedDelegate];
	} else {
		[self emitAdType:@"rewarded" event:@"failed" message:@"Rewarded ad unit ID is empty."];
	}

	if (interstitialAdUnitId.length > 0) {
		self.interstitialDelegate = [[GodotLevelPlayInterstitialDelegate alloc] initWithBridge:self];
		self.interstitialAd = [[LPMInterstitialAd alloc] initWithAdUnitId:interstitialAdUnitId];
		[self.interstitialAd setDelegate:self.interstitialDelegate];
	} else {
		[self emitAdType:@"interstitial" event:@"failed" message:@"Interstitial ad unit ID is empty."];
	}

	if (bannerAdUnitId.length > 0) {
		self.bannerDelegate = [[GodotLevelPlayBannerDelegate alloc] initWithBridge:self];
		self.bannerSize = [LPMAdSize createAdaptiveAdSize];
		if (self.bannerSize == nil) {
			self.bannerSize = [LPMAdSize bannerSize];
		}
		LPMBannerAdViewConfigBuilder *builder = [[LPMBannerAdViewConfigBuilder alloc] init];
		[builder setWithAdSize:self.bannerSize];
		if (self.bannerPlacement.length > 0) {
			[builder setWithPlacementName:self.bannerPlacement];
		}
		self.bannerAd = [[LPMBannerAdView alloc] initWithAdUnitId:bannerAdUnitId config:[builder build]];
		[self.bannerAd setDelegate:self.bannerDelegate];
		self.bannerAd.hidden = YES;
	} else {
		[self emitAdType:@"banner" event:@"failed" message:@"Banner ad unit ID is empty."];
	}
}

- (void)loadRewarded {
	[self runOnMain:^{
		if (!self.initialized || self.rewardedAd == nil) {
			[self emitAdType:@"rewarded" event:@"failed" message:@"Rewarded ad unit is not configured."];
			return;
		}
		[self emitAdType:@"rewarded" event:@"loading" message:@"Loading rewarded ad."];
		[self.rewardedAd loadAd];
	}];
}

- (void)showRewarded:(NSString *)placementName {
	[self runOnMain:^{
		UIViewController *controller = active_view_controller();
		if (controller == nil || self.rewardedAd == nil || !self.rewardedAd.isAdReady) {
			[self emitAdType:@"rewarded" event:@"show_failed" message:@"Rewarded ad is not ready."];
			return;
		}
		NSString *placement = placementName.length > 0 ? placementName : nil;
		[self.rewardedAd showAdWithViewController:controller placementName:placement];
	}];
}

- (void)loadInterstitial {
	[self runOnMain:^{
		if (!self.initialized || self.interstitialAd == nil) {
			[self emitAdType:@"interstitial" event:@"failed" message:@"Interstitial ad unit is not configured."];
			return;
		}
		[self emitAdType:@"interstitial" event:@"loading" message:@"Loading interstitial ad."];
		[self.interstitialAd loadAd];
	}];
}

- (void)showInterstitial:(NSString *)placementName {
	[self runOnMain:^{
		UIViewController *controller = active_view_controller();
		if (controller == nil || self.interstitialAd == nil || !self.interstitialAd.isAdReady) {
			[self emitAdType:@"interstitial" event:@"show_failed" message:@"Interstitial ad is not ready."];
			return;
		}
		NSString *placement = placementName.length > 0 ? placementName : nil;
		[self.interstitialAd showAdWithViewController:controller placementName:placement];
	}];
}

- (void)showBanner {
	[self runOnMain:^{
		UIViewController *controller = active_view_controller();
		if (controller == nil || self.bannerAd == nil) {
			[self emitAdType:@"banner" event:@"failed" message:@"Banner ad unit is not configured."];
			return;
		}
		if (self.bannerAd.superview == nil) {
			self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
			[controller.view addSubview:self.bannerAd];
			UILayoutGuide *safeArea = controller.view.safeAreaLayoutGuide;
			[NSLayoutConstraint activateConstraints:@[
				[self.bannerAd.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
				[self.bannerAd.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
				[self.bannerAd.widthAnchor constraintEqualToConstant:self.bannerSize.width],
				[self.bannerAd.heightAnchor constraintEqualToConstant:self.bannerSize.height],
			]];
		}
		self.bannerAd.hidden = NO;
		[self.bannerAd resumeAutoRefresh];
		[self emitAdType:@"banner" event:@"loading" message:@"Loading banner ad."];
		[self.bannerAd loadAdWithViewController:controller];
	}];
}

- (void)hideBanner {
	[self runOnMain:^{
		[self.bannerAd pauseAutoRefresh];
		self.bannerAd.hidden = YES;
		[self emitAdType:@"banner" event:@"hidden" message:@"Banner hidden."];
	}];
}

- (void)shutdown {
	self.owner = nullptr;
	[self.bannerAd pauseAutoRefresh];
	[self.bannerAd destroy];
	[self.bannerAd removeFromSuperview];
	self.bannerAd = nil;
	self.rewardedAd = nil;
	self.interstitialAd = nil;
	self.rewardedDelegate = nil;
	self.interstitialDelegate = nil;
	self.bannerDelegate = nil;
	self.initialized = NO;
	self.initializing = NO;
}

- (void)emitAdType:(NSString *)adType event:(NSString *)event message:(NSString *)message {
	if (self.owner != nullptr) {
		self.owner->emit_ad_event(to_godot_string(adType), to_godot_string(event), to_godot_string(message));
	}
}

@end

void LevelPlayAds::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize", "app_key", "rewarded_ad_unit_id", "interstitial_ad_unit_id", "banner_ad_unit_id", "enable_test_suite", "banner_placement"), &LevelPlayAds::initialize);
	ClassDB::bind_method(D_METHOD("loadRewarded"), &LevelPlayAds::loadRewarded);
	ClassDB::bind_method(D_METHOD("showRewarded", "placement_name"), &LevelPlayAds::showRewarded);
	ClassDB::bind_method(D_METHOD("loadInterstitial"), &LevelPlayAds::loadInterstitial);
	ClassDB::bind_method(D_METHOD("showInterstitial", "placement_name"), &LevelPlayAds::showInterstitial);
	ClassDB::bind_method(D_METHOD("showBanner"), &LevelPlayAds::showBanner);
	ClassDB::bind_method(D_METHOD("hideBanner"), &LevelPlayAds::hideBanner);

	ADD_SIGNAL(MethodInfo("sdk_initialized", PropertyInfo(Variant::BOOL, "success"), PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("ad_event", PropertyInfo(Variant::STRING, "ad_type"), PropertyInfo(Variant::STRING, "event_name"), PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("reward_earned", PropertyInfo(Variant::STRING, "reward_name"), PropertyInfo(Variant::INT, "amount")));
}

LevelPlayAds::LevelPlayAds() {
	GodotLevelPlayBridge *bridge = [[GodotLevelPlayBridge alloc] initWithOwner:this];
	native_bridge = (__bridge_retained void *)bridge;
}

LevelPlayAds::~LevelPlayAds() {
	if (native_bridge == nullptr) {
		return;
	}
	GodotLevelPlayBridge *bridge = (__bridge_transfer GodotLevelPlayBridge *)native_bridge;
	[bridge shutdown];
	native_bridge = nullptr;
}

void LevelPlayAds::initialize(
		const String &p_app_key,
		const String &p_rewarded_ad_unit_id,
		const String &p_interstitial_ad_unit_id,
		const String &p_banner_ad_unit_id,
		bool p_enable_test_suite,
		const String &p_banner_placement) {
	GodotLevelPlayBridge *bridge = (__bridge GodotLevelPlayBridge *)native_bridge;
	[bridge initializeWithAppKey:to_ns_string(p_app_key)
			rewardedAdUnitId:to_ns_string(p_rewarded_ad_unit_id)
		interstitialAdUnitId:to_ns_string(p_interstitial_ad_unit_id)
			  bannerAdUnitId:to_ns_string(p_banner_ad_unit_id)
			 enableTestSuite:p_enable_test_suite
			 bannerPlacement:to_ns_string(p_banner_placement)];
}

void LevelPlayAds::loadRewarded() {
	[(__bridge GodotLevelPlayBridge *)native_bridge loadRewarded];
}

void LevelPlayAds::showRewarded(const String &p_placement_name) {
	[(__bridge GodotLevelPlayBridge *)native_bridge showRewarded:to_ns_string(p_placement_name)];
}

void LevelPlayAds::loadInterstitial() {
	[(__bridge GodotLevelPlayBridge *)native_bridge loadInterstitial];
}

void LevelPlayAds::showInterstitial(const String &p_placement_name) {
	[(__bridge GodotLevelPlayBridge *)native_bridge showInterstitial:to_ns_string(p_placement_name)];
}

void LevelPlayAds::showBanner() {
	[(__bridge GodotLevelPlayBridge *)native_bridge showBanner];
}

void LevelPlayAds::hideBanner() {
	[(__bridge GodotLevelPlayBridge *)native_bridge hideBanner];
}

void LevelPlayAds::emit_sdk_initialized(bool p_success, const String &p_message) {
	emit_signal("sdk_initialized", p_success, p_message);
}

void LevelPlayAds::emit_ad_event(const String &p_ad_type, const String &p_event_name, const String &p_message) {
	emit_signal("ad_event", p_ad_type, p_event_name, p_message);
}

void LevelPlayAds::emit_reward_earned(const String &p_reward_name, int p_amount) {
	emit_signal("reward_earned", p_reward_name, p_amount);
}
