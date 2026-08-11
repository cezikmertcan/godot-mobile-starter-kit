#include "levelplay_ads_module.h"

#include "core/config/engine.h"
#include "core/os/memory.h"

#include "levelplay_ads.h"

static LevelPlayAds *levelplay_ads_singleton = nullptr;

__attribute__((visibility("default"))) void levelplay_ads_initialize() {
	if (levelplay_ads_singleton != nullptr) {
		return;
	}

	levelplay_ads_singleton = memnew(LevelPlayAds);
	Engine::get_singleton()->add_singleton(Engine::Singleton("LevelPlayAds", levelplay_ads_singleton));
}

__attribute__((visibility("default"))) void levelplay_ads_deinitialize() {
	if (levelplay_ads_singleton == nullptr) {
		return;
	}

	memdelete(levelplay_ads_singleton);
	levelplay_ads_singleton = nullptr;
}
