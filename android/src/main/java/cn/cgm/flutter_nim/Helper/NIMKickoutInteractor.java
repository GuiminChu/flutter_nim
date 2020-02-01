package cn.cgm.flutter_nim.Helper;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.Observer;
import com.netease.nimlib.sdk.StatusCode;
import com.netease.nimlib.sdk.auth.AuthServiceObserver;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.EventChannel;

public class NIMKickoutInteractor {
    private EventChannel.EventSink eventSink;

    public NIMKickoutInteractor(EventChannel.EventSink eventSink) {

        this.eventSink = eventSink;

        registerObservers(true);
    }

    private void registerObservers(boolean register) {
        // 用户状态监听
        Observer<StatusCode> userStatusObserver =
                new Observer<StatusCode>() {

                    @Override
                    public void onEvent(StatusCode code) {
                        if (code.wontAutoLogin()) {
                            // 账号在其他设备登录
                            if (code == StatusCode.KICKOUT) {
                                handleKickCode(1);
                            } else if (code == StatusCode.FORBIDDEN) {
                                handleKickCode(2);
                            } else if (code == StatusCode.KICK_BY_OTHER_CLIENT) {
                                handleKickCode(3);
                            }
                        } else {
                            if (code == StatusCode.NET_BROKEN) {
                                //
                            } else if (code == StatusCode.UNLOGIN) {
                                //
                            } else if (code == StatusCode.CONNECTING) {
                                //
                            } else if (code == StatusCode.LOGINING) {
                                //
                            } else {
                                //
                            }
                        }
                    }
                };

        NIMClient.getService(AuthServiceObserver.class)
                .observeOnlineStatus(userStatusObserver, register);
    }

    private void handleKickCode(int kickCode) {
        if (this.eventSink == null) {
            return;
        }

        JSONObject imObject = new JSONObject();

        try {
            imObject.put("kickCode", kickCode);
        } catch (JSONException exception) {
            exception.printStackTrace();
        }

        String result = imObject.toString();

        eventSink.success(result);
    }

}
