package com.clickaround.sadam

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.clickaround.sadam.adfit.AdFitInterstitialHandler
import com.clickaround.sadam.adfit.AdFitNativeAdFactory

// FlutterFragmentActivity: AdFitPopupAdDialogFragment에 supportFragmentManager 필요
class MainActivity : FlutterFragmentActivity() {
    private var adFitHandler: AdFitInterstitialHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // AdFit MethodChannel (앱 전환 광고)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.clickaround.sadam/adfit")
        adFitHandler = AdFitInterstitialHandler(this, channel)
        adFitHandler?.registerEventListener()
        channel.setMethodCallHandler { call, result ->
            adFitHandler?.handleMethodCall(call, result) ?: result.notImplemented()
        }

        // AdFit PlatformView (네이티브 광고)
        flutterEngine.platformViewsController.registry
            .registerViewFactory("adfit-native-ad", AdFitNativeAdFactory(this, flutterEngine.dartExecutor.binaryMessenger))
    }

    override fun onDestroy() {
        adFitHandler?.destroy()
        super.onDestroy()
    }
}
