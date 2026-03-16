package com.clickaround.sadam.adfit

import android.util.Log
import androidx.annotation.UiThread
import androidx.fragment.app.FragmentActivity
import com.kakao.adfit.ads.popup.AdFitPopupAd
import com.kakao.adfit.ads.popup.AdFitPopupAdDialogFragment
import com.kakao.adfit.ads.popup.AdFitPopupAdLoader
import com.kakao.adfit.ads.popup.AdFitPopupAdRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * AdFit 앱 전환(팝업) 광고 핸들러
 *
 * AdFit SDK의 AdFitPopupAdLoader + AdFitPopupAdDialogFragment 사용.
 * Flutter MethodChannel로 loadInterstitial / showInterstitial 처리.
 *
 * @see <a href="https://github.com/adfit/adfit-android-sdk/blob/master/docs/app-transition-ad.md">공식 문서</a>
 */
class AdFitInterstitialHandler(
    private val activity: FragmentActivity,
    private val channel: MethodChannel
) {
    companion object {
        private const val TAG = "AdFitInterstitial"
    }

    private var popupAdLoader: AdFitPopupAdLoader? = null
    private var loadedAd: AdFitPopupAd? = null
    private var isLoaded = false

    /**
     * FragmentResultListener 등록 — Activity.onCreate() 후 호출 필수
     */
    fun registerEventListener() {
        activity.supportFragmentManager.setFragmentResultListener(
            AdFitPopupAdDialogFragment.REQUEST_KEY_POPUP_AD,
            activity
        ) { _, bundle ->
            when (bundle.getString(AdFitPopupAdDialogFragment.BUNDLE_KEY_EVENT_TYPE)) {
                AdFitPopupAdDialogFragment.EVENT_AD_CLICKED -> {
                    Log.d(TAG, "Popup ad clicked")
                    activity.runOnUiThread {
                        channel.invokeMethod("onInterstitialClicked", null)
                    }
                }

                AdFitPopupAdDialogFragment.EVENT_POPUP_DISMISSED,
                AdFitPopupAdDialogFragment.EVENT_POPUP_CANCELED,
                AdFitPopupAdDialogFragment.EVENT_BACK_PRESSED,
                AdFitPopupAdDialogFragment.EVENT_TODAY_DISMISSED -> {
                    Log.d(TAG, "Popup ad dismissed")
                    isLoaded = false
                    loadedAd = null
                    activity.runOnUiThread {
                        channel.invokeMethod("onInterstitialDismissed", null)
                    }
                }
            }
        }
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadInterstitial" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: return result.error(
                    "INVALID_ARGUMENT", "adUnitId is required", null
                )
                loadInterstitial(adUnitId, result)
            }
            "showInterstitial" -> {
                showInterstitial(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadInterstitial(adUnitId: String, result: MethodChannel.Result) {
        try {
            // 기존 로더 정리
            popupAdLoader?.destroy()
            loadedAd = null
            isLoaded = false

            popupAdLoader = AdFitPopupAdLoader.create(activity, adUnitId)

            val request = AdFitPopupAdRequest.build(AdFitPopupAd.Type.Transition)

            popupAdLoader?.loadAd(request, object : AdFitPopupAdLoader.OnAdLoadListener {
                @UiThread
                override fun onAdLoaded(ad: AdFitPopupAd) {
                    if (activity.isFinishing || activity.isDestroyed) return

                    Log.d(TAG, "Popup ad loaded")
                    loadedAd = ad
                    isLoaded = true
                    activity.runOnUiThread {
                        channel.invokeMethod("onInterstitialLoaded", null)
                    }
                }

                @UiThread
                override fun onAdLoadError(errorCode: Int) {
                    Log.e(TAG, "Popup ad load error: $errorCode")
                    isLoaded = false
                    activity.runOnUiThread {
                        channel.invokeMethod("onInterstitialLoadFailed", mapOf("errorCode" to errorCode))
                    }
                }
            })

            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "loadInterstitial error: ${e.message}")
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun showInterstitial(result: MethodChannel.Result) {
        val ad = loadedAd
        if (!isLoaded || ad == null) {
            result.success(false)
            return
        }

        if (activity.isFinishing || activity.isDestroyed) {
            result.success(false)
            return
        }

        // 이미 팝업이 표시 중인지 확인
        val isShowing = activity.supportFragmentManager
            .findFragmentByTag(AdFitPopupAdDialogFragment.TAG) != null
        if (isShowing) {
            result.success(false)
            return
        }

        try {
            AdFitPopupAdDialogFragment.Builder(ad)
                .build()
                .show(activity.supportFragmentManager, AdFitPopupAdDialogFragment.TAG)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "showInterstitial error: ${e.message}")
            isLoaded = false
            loadedAd = null
            result.error("SHOW_ERROR", e.message, null)
        }
    }

    fun destroy() {
        popupAdLoader?.destroy()
        popupAdLoader = null
        loadedAd = null
        isLoaded = false
    }
}
