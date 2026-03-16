package com.clickaround.sadam.adfit

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.clickaround.sadam.R
import com.kakao.adfit.ads.na.AdFitAdInfoIconPosition
import com.kakao.adfit.ads.na.AdFitNativeAdBinder
import com.kakao.adfit.ads.na.AdFitNativeAdLayout
import com.kakao.adfit.ads.na.AdFitNativeAdLoader
import com.kakao.adfit.ads.na.AdFitNativeAdRequest
import com.kakao.adfit.ads.na.AdFitNativeAdView
import com.kakao.adfit.ads.na.AdFitVideoAutoPlayPolicy
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * AdFit 네이티브 광고 PlatformView Factory
 *
 * Flutter의 AndroidView(viewType: 'adfit-native-ad')와 연결.
 *
 * @see <a href="https://github.com/adfit/adfit-android-sdk/blob/master/docs/NATIVEAD.md">공식 문서</a>
 */
class AdFitNativeAdFactory(
    private val activity: Activity,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val adUnitId = params?.get("adUnitId") as? String ?: ""
        return AdFitNativeAdPlatformView(activity, messenger, viewId, adUnitId)
    }
}

/**
 * AdFit 네이티브 광고 PlatformView
 *
 * AdFitNativeAdLayout + AdFitNativeAdBinder 방식으로 SDK가 자동 렌더링.
 * containerView는 AdFitNativeAdView, mediaView는 AdFitMediaView 사용 (필수).
 */
class AdFitNativeAdPlatformView(
    private val activity: Activity,
    messenger: BinaryMessenger,
    private val viewId: Int,
    private val adUnitId: String
) : PlatformView {

    companion object {
        private const val TAG = "AdFitNativeAd"
    }

    private val container: FrameLayout = FrameLayout(activity)
    private var nativeAdLoader: AdFitNativeAdLoader? = null
    private var nativeAdBinder: AdFitNativeAdBinder? = null
    private var nativeAdLayout: AdFitNativeAdLayout? = null
    private val channel = MethodChannel(messenger, "adfit-native-ad/$viewId")

    init {
        loadNativeAd()
    }

    private fun loadNativeAd() {
        nativeAdLoader = AdFitNativeAdLoader.create(activity, adUnitId)

        val request = AdFitNativeAdRequest.Builder()
            .setAdInfoIconPosition(AdFitAdInfoIconPosition.RIGHT_TOP)
            .setVideoAutoPlayPolicy(AdFitVideoAutoPlayPolicy.WIFI_ONLY)
            .build()

        nativeAdLoader?.loadAd(request, object : AdFitNativeAdLoader.AdLoadListener {
            override fun onAdLoaded(binder: AdFitNativeAdBinder) {
                Log.d(TAG, "Native ad loaded")
                nativeAdBinder = binder
                renderAd(binder)
                activity.runOnUiThread {
                    channel.invokeMethod("onAdLoaded", null)
                }
            }

            override fun onAdLoadError(errorCode: Int) {
                Log.e(TAG, "Native ad load error: $errorCode")
                activity.runOnUiThread {
                    channel.invokeMethod("onAdLoadFailed", mapOf("errorCode" to errorCode))
                }
            }
        })
    }

    private fun renderAd(binder: AdFitNativeAdBinder) {
        activity.runOnUiThread {
            try {
                // 이전 광고 해제
                nativeAdBinder?.unbind()

                val adView = LayoutInflater.from(activity)
                    .inflate(R.layout.adfit_native_ad, container, false)

                // AdFitNativeAdLayout.Builder로 레이아웃 구성 (SDK가 자동으로 소재를 채움)
                val containerView = adView.findViewById<AdFitNativeAdView>(R.id.containerView)
                val titleView = adView.findViewById<TextView>(R.id.titleTextView)
                val bodyView = adView.findViewById<TextView>(R.id.bodyTextView)
                val profileIconView = adView.findViewById<ImageView>(R.id.profileIconView)
                val profileNameView = adView.findViewById<TextView>(R.id.profileNameTextView)
                val mediaView = adView.findViewById<com.kakao.adfit.ads.na.AdFitMediaView>(R.id.mediaView)
                val ctaButton = adView.findViewById<Button>(R.id.callToActionButton)

                val layout = AdFitNativeAdLayout.Builder(containerView)
                    .setTitleView(titleView)
                    .setBodyView(bodyView)
                    .setProfileIconView(profileIconView)
                    .setProfileNameView(profileNameView)
                    .setMediaView(mediaView)
                    .setCallToActionButton(ctaButton)
                    .build()

                nativeAdLayout = layout

                // 클릭 리스너 등록
                binder.onAdClickListener = object : AdFitNativeAdBinder.OnAdClickListener {
                    override fun onAdClicked(view: View) {
                        Log.d(TAG, "Native ad clicked")
                        activity.runOnUiThread {
                            channel.invokeMethod("onAdClicked", null)
                        }
                    }
                }

                // SDK가 레이아웃에 광고 소재를 바인딩 + 노출 측정 시작
                binder.bind(layout)

                container.removeAllViews()
                container.addView(adView)

                // 노출 콜백
                activity.runOnUiThread {
                    channel.invokeMethod("onAdImpression", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "renderAd error: ${e.message}")
            }
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        nativeAdBinder?.unbind()
        nativeAdBinder = null
        nativeAdLoader = null
        nativeAdLayout = null
    }
}
