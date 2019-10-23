package cn.cgm.flutter_nim_example;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.SDKOptions;
import com.netease.nimlib.sdk.mixpush.MixPushConfig;

import cn.cgm.flutter_nim.Helper.FlutterNIMPreferences;
import cn.cgm.flutter_nim.Helper.FlutterNIMSDKOptionConfig;
import io.flutter.app.FlutterApplication;

public class MyApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();

        FlutterNIMPreferences.setContext(this);
        // SDK初始化（启动后台服务，若已经存在用户登录信息， SDK 将完成自动登录）
        NIMClient.init(this, FlutterNIMPreferences.getLoginInfo(), buildSDKOptions());
    }

    // 网易云信配置
    private SDKOptions buildSDKOptions() {
        return FlutterNIMSDKOptionConfig.getSDKOptions(this, "45c6af3c98409b18a84451215d0bdd6e", buildMixPushConfig());
    }

    // 网易云信第三方推送配置
    private MixPushConfig buildMixPushConfig() {

        MixPushConfig config = new MixPushConfig();

        // 小米推送
//        config.xmAppId = "123";
//        config.xmAppKey = "123";
//        config.xmCertificateName = "abc";

        // 华为推送
//        config.hwCertificateName = "abc";

        // Vivo推送
//        config.vivoCertificateName = "abc";

        // 魅族推送
//        config.mzAppId = "123";
//        config.mzAppKey = "123";
//        config.mzCertificateName = "abc";

        // fcm 推送，适用于海外用户，不使用fcm请不要配置
//        config.fcmCertificateName = "DEMO_FCM_PUSH";

        return config;
    }
}
