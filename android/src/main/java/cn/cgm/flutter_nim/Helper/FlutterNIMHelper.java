package cn.cgm.flutter_nim.Helper;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.Observer;
import com.netease.nimlib.sdk.RequestCallback;
import com.netease.nimlib.sdk.ResponseCode;
import com.netease.nimlib.sdk.auth.AuthService;
import com.netease.nimlib.sdk.auth.LoginInfo;
import com.netease.nimlib.sdk.mixpush.MixPushService;
import com.netease.nimlib.sdk.msg.MsgService;
import com.netease.nimlib.sdk.msg.MsgServiceObserve;
import com.netease.nimlib.sdk.msg.model.CustomNotification;
import com.netease.nimlib.sdk.util.NIMUtil;

public class FlutterNIMHelper {

    public interface IMHelperNotificationCallback {
        void onEvent(CustomNotification message);
    }

    public interface IMLoginCallback {
        void onResult(boolean isSuccess);
    }

    private static IMHelperNotificationCallback imHelperNotificationCallback;

    // singleton
    private static FlutterNIMHelper instance;

    public static synchronized FlutterNIMHelper getInstance() {
        if (instance == null) {
            instance = new FlutterNIMHelper();
        }

        return instance;
    }

    private FlutterNIMHelper() {
        registerObservers(true);
    }


    public void registerNotificationCallback(IMHelperNotificationCallback cb) {
        imHelperNotificationCallback = cb;
    }

    public static void initIM(Context context) {
        if (NIMUtil.isMainProcess(context)) {
            // 注册自定义消息附件解析器
            NIMClient.getService(MsgService.class).registerCustomAttachmentParser(new FlutterNIMCustomAttachParser());

            setMessageNotify(true);
        }
    }

    /**
     * IM登录
     */
    public void doIMLogin(String account, String token, final IMLoginCallback loginCallback) {
        final String imAccount = account.toLowerCase();
        final String imToken = token.toLowerCase();

        LoginInfo info = new LoginInfo(imAccount, imToken);

        RequestCallback<LoginInfo> callback =
                new RequestCallback<LoginInfo>() {
                    @Override
                    public void onSuccess(LoginInfo param) {
                        saveLoginInfo(imAccount, imToken);

                        loginCallback.onResult(true);
                    }

                    @Override
                    public void onFailed(int code) {
                        Log.e("FlutterNIM", "im login failure" + code);

                        loginCallback.onResult(false);
                    }

                    @Override
                    public void onException(Throwable exception) {
                        Log.e("FlutterNIM", "im login error");
                    }
                };

        NIMClient.getService(AuthService.class).login(info)
                .setCallback(callback);
    }

    private static LoginInfo getLoginInfo(String account, String token) {
        if (!TextUtils.isEmpty(account) && !TextUtils.isEmpty(token)) {
            return new LoginInfo(account, token);
        } else {
            return null;
        }
    }

    private static void saveLoginInfo(final String account, final String token) {
        FlutterNIMPreferences.saveUserAccount(account);
        FlutterNIMPreferences.saveUserToken(token);
    }

    /**
     * IM登出
     */
    public void doIMLogout() {
        NIMClient.getService(AuthService.class).logout();
    }


    /**
     * ********************** 收消息，处理状态变化 ************************
     */
    private void registerObservers(boolean register) {
        MsgServiceObserve service = NIMClient.getService(MsgServiceObserve.class);

        // 监听自定义通知
        service.observeCustomNotification(customNotificationObserver, register);
    }

    // 接收自定义通知
    Observer<CustomNotification> customNotificationObserver = new Observer<CustomNotification>() {
        @Override
        public void onEvent(CustomNotification message) {
            // 在这里处理自定义通知。
            if (imHelperNotificationCallback != null) {
                imHelperNotificationCallback.onEvent(message);
            }
        }
    };


    /**
     * **************************** 推送 ***********************************
     */
    private static void setMessageNotify(final boolean checkState) {
        // 如果接入第三方推送（小米），则同样应该设置开、关推送提醒
        // 如果关闭消息提醒，则第三方推送消息提醒也应该关闭。
        // 如果打开消息提醒，则同时打开第三方推送消息提醒。
        NIMClient.getService(MixPushService.class).enable(checkState).setCallback(new RequestCallback<Void>() {
            @Override
            public void onSuccess(Void param) {
//                Toast.makeText(SettingsActivity.this, R.string.user_info_update_success, Toast.LENGTH_SHORT).show();
//                notificationItem.setChecked(checkState);
//                setToggleNotification(checkState);
            }

            @Override
            public void onFailed(int code) {
//                notificationItem.setChecked(!checkState);
                // 这种情况是客户端不支持第三方推送
                if (code == ResponseCode.RES_UNSUPPORT) {
                } else if (code == ResponseCode.RES_EFREQUENTLY) {
//                    Toast.makeText(SettingsActivity.this, R.string.operation_too_frequent, Toast.LENGTH_SHORT).show();
                } else {
//                    Toast.makeText(SettingsActivity.this, R.string.user_info_update_failed, Toast.LENGTH_SHORT).show();
                }
//                adapter.notifyDataSetChanged();
            }

            @Override
            public void onException(Throwable exception) {

            }
        });
    }
}
