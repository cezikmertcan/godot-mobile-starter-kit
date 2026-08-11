package com.godotmobile.levelplay

import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.unity3d.mediation.LevelPlay
import com.unity3d.mediation.LevelPlayAdError
import com.unity3d.mediation.LevelPlayAdInfo
import com.unity3d.mediation.LevelPlayAdSize
import com.unity3d.mediation.LevelPlayConfiguration
import com.unity3d.mediation.LevelPlayInitError
import com.unity3d.mediation.LevelPlayInitListener
import com.unity3d.mediation.LevelPlayInitRequest
import com.unity3d.mediation.banner.LevelPlayBannerAdView
import com.unity3d.mediation.banner.LevelPlayBannerAdViewListener
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAd
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAdListener
import com.unity3d.mediation.rewarded.LevelPlayReward
import com.unity3d.mediation.rewarded.LevelPlayRewardedAd
import com.unity3d.mediation.rewarded.LevelPlayRewardedAdListener
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class GodotAndroidPlugin(godot: Godot) : GodotPlugin(godot) {
    private var initialized = false
    private var rewardedAd: LevelPlayRewardedAd? = null
    private var interstitialAd: LevelPlayInterstitialAd? = null
    private var bannerAd: LevelPlayBannerAdView? = null
    private var bannerPlacement = ""

    override fun getPluginName(): String = BuildConfig.GODOT_PLUGIN_NAME

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("sdk_initialized", Boolean::class.javaObjectType, String::class.java),
        SignalInfo("ad_event", String::class.java, String::class.java, String::class.java),
        SignalInfo("reward_earned", String::class.java, Int::class.javaObjectType),
    )

    @UsedByGodot
    fun initialize(
        appKey: String,
        rewardedAdUnitId: String,
        interstitialAdUnitId: String,
        bannerAdUnitId: String,
        enableTestSuite: Boolean,
        placementName: String,
    ) {
        runOnUiThread {
            val currentActivity = activity ?: return@runOnUiThread
            if (initialized) {
                emitHost("sdk_initialized", true, "Unity LevelPlay is already initialized.")
                return@runOnUiThread
            }
            if (appKey.isBlank()) {
                emitHost("sdk_initialized", false, "LevelPlay app key is empty.")
                return@runOnUiThread
            }

            bannerPlacement = placementName
            if (enableTestSuite) {
                LevelPlay.setMetaData("is_test_suite", "enable")
            }

            val initRequest = LevelPlayInitRequest.Builder(appKey).build()
            LevelPlay.init(currentActivity, initRequest, object : LevelPlayInitListener {
                override fun onInitFailed(error: LevelPlayInitError) {
                    initialized = false
                    emitHost("sdk_initialized", false, error.toString())
                }

                override fun onInitSuccess(configuration: LevelPlayConfiguration) {
                    initialized = true
                    createAdObjects(rewardedAdUnitId, interstitialAdUnitId, bannerAdUnitId)
                    emitHost("sdk_initialized", true, "Unity LevelPlay initialization succeeded.")
                }
            })
        }
    }

    @UsedByGodot
    fun loadRewarded() {
        runOnUiThread {
            val ad = rewardedAd
            if (ad == null) {
                emitAdEvent("rewarded", "failed", "Rewarded ad unit is not configured.")
                return@runOnUiThread
            }
            emitAdEvent("rewarded", "loading", "Loading rewarded ad.")
            ad.loadAd()
        }
    }

    @UsedByGodot
    fun showRewarded(placementName: String) {
        runOnUiThread {
            val currentActivity = activity ?: return@runOnUiThread
            val ad = rewardedAd
            if (ad == null || !ad.isAdReady()) {
                emitAdEvent("rewarded", "show_failed", "Rewarded ad is not ready.")
                return@runOnUiThread
            }
            if (placementName.isBlank()) {
                ad.showAd(currentActivity)
            } else {
                ad.showAd(currentActivity, placementName)
            }
        }
    }

    @UsedByGodot
    fun loadInterstitial() {
        runOnUiThread {
            val ad = interstitialAd
            if (ad == null) {
                emitAdEvent("interstitial", "failed", "Interstitial ad unit is not configured.")
                return@runOnUiThread
            }
            emitAdEvent("interstitial", "loading", "Loading interstitial ad.")
            ad.loadAd()
        }
    }

    @UsedByGodot
    fun showInterstitial(placementName: String) {
        runOnUiThread {
            val currentActivity = activity ?: return@runOnUiThread
            val ad = interstitialAd
            if (ad == null || !ad.isAdReady()) {
                emitAdEvent("interstitial", "show_failed", "Interstitial ad is not ready.")
                return@runOnUiThread
            }
            if (placementName.isBlank()) {
                ad.showAd(currentActivity)
            } else {
                ad.showAd(currentActivity, placementName)
            }
        }
    }

    @UsedByGodot
    fun showBanner() {
        runOnUiThread {
            val ad = bannerAd
            if (ad == null) {
                emitAdEvent("banner", "failed", "Banner ad unit is not configured.")
                return@runOnUiThread
            }
            attachBanner(ad)
            ad.visibility = View.VISIBLE
            emitAdEvent("banner", "loading", "Loading banner ad.")
            ad.loadAd()
        }
    }

    @UsedByGodot
    fun hideBanner() {
        runOnUiThread {
            bannerAd?.let {
                it.pauseAutoRefresh()
                it.visibility = View.GONE
            }
            emitAdEvent("banner", "hidden", "Banner hidden.")
        }
    }

    private fun createAdObjects(
        rewardedAdUnitId: String,
        interstitialAdUnitId: String,
        bannerAdUnitId: String,
    ) {
        val currentActivity = activity ?: return
        rewardedAd = null
        interstitialAd = null
        bannerAd = null

        if (rewardedAdUnitId.isNotBlank()) {
            rewardedAd = LevelPlayRewardedAd(rewardedAdUnitId).also { ad ->
                ad.setListener(object : LevelPlayRewardedAdListener {
                    override fun onAdLoaded(adInfo: LevelPlayAdInfo) = emitAdEvent("rewarded", "loaded", "Rewarded ad loaded.")
                    override fun onAdLoadFailed(error: LevelPlayAdError) = emitAdEvent("rewarded", "failed", error.toString())
                    override fun onAdDisplayed(adInfo: LevelPlayAdInfo) = emitAdEvent("rewarded", "displayed", "Rewarded ad displayed.")
                    override fun onAdDisplayFailed(error: LevelPlayAdError, adInfo: LevelPlayAdInfo) = emitAdEvent("rewarded", "failed", error.toString())
                    override fun onAdClicked(adInfo: LevelPlayAdInfo) = emitAdEvent("rewarded", "clicked", "Rewarded ad clicked.")
                    override fun onAdClosed(adInfo: LevelPlayAdInfo) {
                        emitAdEvent("rewarded", "closed", "Rewarded ad closed.")
                        ad.loadAd()
                    }
                    override fun onAdInfoChanged(adInfo: LevelPlayAdInfo) = emitAdEvent("rewarded", "info_changed", "Rewarded ad info changed.")
                    override fun onAdRewarded(reward: LevelPlayReward, adInfo: LevelPlayAdInfo) {
                        emitHost("reward_earned", reward.name, reward.amount)
                        emitAdEvent("rewarded", "rewarded", "Reward received.")
                    }
                })
            }
        } else {
            emitAdEvent("rewarded", "failed", "Rewarded ad unit ID is empty.")
        }

        if (interstitialAdUnitId.isNotBlank()) {
            interstitialAd = LevelPlayInterstitialAd(interstitialAdUnitId).also { ad ->
                ad.setListener(object : LevelPlayInterstitialAdListener {
                    override fun onAdLoaded(adInfo: LevelPlayAdInfo) = emitAdEvent("interstitial", "loaded", "Interstitial ad loaded.")
                    override fun onAdLoadFailed(error: LevelPlayAdError) = emitAdEvent("interstitial", "failed", error.toString())
                    override fun onAdDisplayed(adInfo: LevelPlayAdInfo) = emitAdEvent("interstitial", "displayed", "Interstitial ad displayed.")
                    override fun onAdDisplayFailed(error: LevelPlayAdError, adInfo: LevelPlayAdInfo) = emitAdEvent("interstitial", "failed", error.toString())
                    override fun onAdClicked(adInfo: LevelPlayAdInfo) = emitAdEvent("interstitial", "clicked", "Interstitial ad clicked.")
                    override fun onAdClosed(adInfo: LevelPlayAdInfo) {
                        emitAdEvent("interstitial", "closed", "Interstitial ad closed.")
                        ad.loadAd()
                    }
                    override fun onAdInfoChanged(adInfo: LevelPlayAdInfo) = emitAdEvent("interstitial", "info_changed", "Interstitial ad info changed.")
                })
            }
        } else {
            emitAdEvent("interstitial", "failed", "Interstitial ad unit ID is empty.")
        }

        if (bannerAdUnitId.isNotBlank()) {
            val builder = LevelPlayBannerAdView.Config.Builder().setAdSize(LevelPlayAdSize.BANNER)
            if (bannerPlacement.isNotBlank()) {
                builder.setPlacementName(bannerPlacement)
            }
            bannerAd = LevelPlayBannerAdView(currentActivity, bannerAdUnitId, builder.build()).also { ad ->
                ad.setBannerListener(object : LevelPlayBannerAdViewListener {
                    override fun onAdLoaded(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "loaded", "Banner ad loaded.")
                    override fun onAdLoadFailed(error: LevelPlayAdError) = emitAdEvent("banner", "failed", error.toString())
                    override fun onAdDisplayed(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "displayed", "Banner ad displayed.")
                    override fun onAdDisplayFailed(adInfo: LevelPlayAdInfo, error: LevelPlayAdError) = emitAdEvent("banner", "failed", error.toString())
                    override fun onAdClicked(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "clicked", "Banner ad clicked.")
                    override fun onAdExpanded(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "expanded", "Banner expanded.")
                    override fun onAdCollapsed(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "collapsed", "Banner collapsed.")
                    override fun onAdLeftApplication(adInfo: LevelPlayAdInfo) = emitAdEvent("banner", "left_application", "Banner opened another application.")
                })
                ad.visibility = View.GONE
            }
        } else {
            emitAdEvent("banner", "failed", "Banner ad unit ID is empty.")
        }
    }

    private fun attachBanner(ad: LevelPlayBannerAdView) {
        val parent = ad.parent as? ViewGroup
        if (parent != null) {
            return
        }
        val currentActivity = activity ?: return
        val contentRoot = currentActivity.findViewById<ViewGroup>(android.R.id.content) ?: return
        val layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        }
        contentRoot.addView(ad, layoutParams)
    }

    private fun emitAdEvent(adType: String, eventName: String, message: String) {
        emitHost("ad_event", adType, eventName, message)
    }

    private fun emitHost(signalName: String, vararg args: Any) {
        runOnHostThread {
            emitSignal(signalName, *args)
        }
    }

    override fun onMainPause() {
        super.onMainPause()
        runOnUiThread { bannerAd?.pauseAutoRefresh() }
    }

    override fun onMainResume() {
        super.onMainResume()
        runOnUiThread {
            if (bannerAd?.visibility == View.VISIBLE) {
                bannerAd?.resumeAutoRefresh()
            }
        }
    }

    override fun onMainDestroy() {
        runOnUiThread {
            bannerAd?.destroy()
            bannerAd = null
            rewardedAd = null
            interstitialAd = null
            initialized = false
        }
        super.onMainDestroy()
    }
}
