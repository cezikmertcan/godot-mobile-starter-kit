#ifndef LEVELPLAY_ADS_H
#define LEVELPLAY_ADS_H

#include "core/object/object.h"
#include "core/string/ustring.h"

class LevelPlayAds : public Object {
	GDCLASS(LevelPlayAds, Object);

	void *native_bridge = nullptr;

protected:
	static void _bind_methods();

public:
	void initialize(
			const String &p_app_key,
			const String &p_rewarded_ad_unit_id,
			const String &p_interstitial_ad_unit_id,
			const String &p_banner_ad_unit_id,
			bool p_enable_test_suite,
			const String &p_banner_placement);
	void loadRewarded();
	void showRewarded(const String &p_placement_name);
	void loadInterstitial();
	void showInterstitial(const String &p_placement_name);
	void showBanner();
	void hideBanner();

	// Called by the Objective-C++ delegate objects on the iOS main thread.
	void emit_sdk_initialized(bool p_success, const String &p_message);
	void emit_ad_event(const String &p_ad_type, const String &p_event_name, const String &p_message);
	void emit_reward_earned(const String &p_reward_name, int p_amount);

	LevelPlayAds();
	~LevelPlayAds();
};

#endif // LEVELPLAY_ADS_H
