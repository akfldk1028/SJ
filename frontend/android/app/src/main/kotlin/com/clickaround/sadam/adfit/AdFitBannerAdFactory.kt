package com.clickaround.sadam.adfit

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import com.kakao.adfit.ads.AdListener
import com.kakao.adfit.ads.ba.BannerAdView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * AdFit 배너 광고 PlatformView Factory
 *
 * Flutter의 AndroidView(viewType: 'adfit-banner-ad')와 연결.
 * 320x100 사이즈 배너.
 */
class AdFitBannerAdFactory(
    private val activity: Activity,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val adUnitId = params?.get("adUnitId") as? String ?: ""
        return AdFitBannerAdPlatformView(activity, messenger, viewId, adUnitId)
    }
}

/**
 * AdFit 배너 광고 PlatformView
 */
class AdFitBannerAdPlatformView(
    private val activity: Activity,
    messenger: BinaryMessenger,
    viewId: Int,
    adUnitId: String
) : PlatformView {

    companion object {
        private const val TAG = "AdFitBannerAd"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val bannerAdView: BannerAdView = BannerAdView(activity)
    private val channel = MethodChannel(messenger, "adfit-banner-ad/$viewId")

    init {
        bannerAdView.setClientId(adUnitId)
        bannerAdView.setAdListener(object : AdListener {
            override fun onAdLoaded() {
                Log.d(TAG, "Banner ad loaded")
                mainHandler.post { channel.invokeMethod("onAdLoaded", null) }
            }

            override fun onAdFailed(errorCode: Int) {
                Log.e(TAG, "Banner ad load failed: $errorCode")
                mainHandler.post { channel.invokeMethod("onAdLoadFailed", mapOf("errorCode" to errorCode)) }
            }

            override fun onAdClicked() {
                Log.d(TAG, "Banner ad clicked")
                mainHandler.post { channel.invokeMethod("onAdClicked", null) }
            }
        })
        bannerAdView.loadAd()
    }

    override fun getView(): View = bannerAdView

    override fun dispose() {
        bannerAdView.destroy()
    }
}
