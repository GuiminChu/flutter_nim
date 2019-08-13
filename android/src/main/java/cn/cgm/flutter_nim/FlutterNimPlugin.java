package cn.cgm.flutter_nim;

import android.app.Application;

import cn.cgm.flutter_nim.Helper.FlutterNIMHelper;
import cn.cgm.flutter_nim.Helper.FlutterNIMPreferences;
import cn.cgm.flutter_nim.Helper.NIMRecentSessionsInteractor;
import cn.cgm.flutter_nim.Helper.NIMSessionInteractor;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterNimPlugin
 * <p/>
 *
 * @author chuguimin
 */
public class FlutterNimPlugin implements MethodCallHandler, EventChannel.StreamHandler {
    private static final String METHOD_CHANNEL_NAME = "flutter_nim_method";
    private static final String EVENT_CHANNEL_NAME = "flutter_nim_event";

    private static final String METHOD_IM_INIT = "imInit";
    private static final String METHOD_IM_LOGIN = "imLogin";
    private static final String METHOD_IM_LOGOUT = "imLogout";
    private static final String METHOD_IM_RECENT_SESSIONS = "imRecentSessions";
    private static final String METHOD_IM_DELETE_RECENT_SESSION = "imDeleteRecentSession";
    private static final String METHOD_IM_START_CHAT = "imStartChat";
    private static final String METHOD_IM_EXIT_CHAT = "imExitChat";
    private static final String METHOD_IM_MESSAGES = "imMessages";
    private static final String METHOD_IM_SEND_TEXT = "imSendText";
    private static final String METHOD_IM_SEND_IMAGE = "imSendImage";
    private static final String METHOD_IM_SEND_VIDEO = "imSendVideo";
    private static final String METHOD_IM_SEND_AUDIO = "imSendAudio";
    private static final String METHOD_IM_SEND_CUSTOM = "imSendCustom";
    private static final String METHOD_IM_SEND_CUSTOM_2 = "imSendCustomToSession";
    private static final String METHOD_IM_RESEND_MESSAGE = "imResendMessage";
    private static final String METHOD_IM_MARK_READ = "imMarkAudioMessageRead";
    private static final String METHOD_IM_RECORD_START = "onStartRecording";
    private static final String METHOD_IM_RECORD_STOP = "onStopRecording";
    private static final String METHOD_IM_RECORD_CANCEL = "onCancelRecording";


    private final PluginRegistry.Registrar registrar;
    private EventChannel.EventSink eventSink;

    private NIMRecentSessionsInteractor recentSessionsInteractor;

    private NIMSessionInteractor sessionInteractor;


    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel methodChannel = new MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME);
        final EventChannel eventChannel =
                new EventChannel(registrar.messenger(), EVENT_CHANNEL_NAME);

        final FlutterNimPlugin instance = new FlutterNimPlugin(registrar);

        methodChannel.setMethodCallHandler(instance);
        eventChannel.setStreamHandler(instance);
    }

    private FlutterNimPlugin(PluginRegistry.Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        handleMethodChannel(call, result);
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
        recentSessionsInteractor = new NIMRecentSessionsInteractor(eventSink);
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }


    private void handleMethodChannel(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case METHOD_IM_INIT:
                imInit();

                break;
            case METHOD_IM_LOGIN:
                String account = methodCall.argument("imAccount");
                String token = methodCall.argument("imToken");
                doIMLogin(account, token, result);

                break;
            case METHOD_IM_LOGOUT:
                FlutterNIMHelper.getInstance().doIMLogout();
                FlutterNIMPreferences.clear();

                break;
            case METHOD_IM_RECENT_SESSIONS:
                recentSessionsInteractor.loadRecentSessions();

                break;
            case METHOD_IM_DELETE_RECENT_SESSION:
                String deletedSessionId = methodCall.argument("sessionId");

                recentSessionsInteractor.deleteRecentContact2(deletedSessionId);
                break;
            case METHOD_IM_START_CHAT:
                String sessionId = methodCall.argument("sessionId");
                startChat(sessionId, result);

                break;
            case METHOD_IM_EXIT_CHAT:
                if (sessionInteractor != null) {
                    sessionInteractor.onDestroy();
                    sessionInteractor = null;
                }

                break;
            case METHOD_IM_MESSAGES:
                int messageIndex = methodCall.argument("messageIndex");
                sessionInteractor.loadHistoryMessages(messageIndex);

                break;
            case METHOD_IM_SEND_TEXT:
                String text = methodCall.argument("text");
                if (sessionInteractor != null) {
                    sessionInteractor.sendTextMessage(text);
                }

                break;
            case METHOD_IM_SEND_IMAGE:
                String imagePath = methodCall.argument("imagePath");
                if (sessionInteractor != null) {
                    sessionInteractor.sendImageMessage(imagePath);
                }

                break;
            case METHOD_IM_SEND_VIDEO:
                String videoPath = methodCall.argument("videoPath");
                if (sessionInteractor != null) {
                    sessionInteractor.sendVideoMessage(videoPath);
                }

                break;
            case METHOD_IM_SEND_AUDIO:
                String audioPath = methodCall.argument("audioPath");
                if (sessionInteractor != null) {
                    sessionInteractor.sendAudioMessage(audioPath);
                }

                break;
            case METHOD_IM_SEND_CUSTOM:
                String customEncodeString = methodCall.argument("customEncodeString");
                String apnsContent = methodCall.argument("apnsContent");

                if (sessionInteractor != null) {
                    sessionInteractor.sendCustomMessage(customEncodeString, apnsContent);
                }

                break;
            case METHOD_IM_SEND_CUSTOM_2:
                String sessionId2 = methodCall.argument("sessionId");
                String customEncodeString2 = methodCall.argument("customEncodeString");
                String apnsContent2 = methodCall.argument("apnsContent");

                NIMSessionInteractor.sendCustomMessageToSession(sessionId2, customEncodeString2, apnsContent2);
                result.success(true);

                break;
            case METHOD_IM_RESEND_MESSAGE:
                String messageId = methodCall.argument("messageId");
                if (sessionInteractor != null) {
                    sessionInteractor.resendMessage(messageId);
                }

                break;
            case METHOD_IM_MARK_READ:
                String audioMessageId = methodCall.argument("messageId");
                if (sessionInteractor != null) {
                    sessionInteractor.markAudioMessageRead(audioMessageId);
                    result.success(true);
                }

                break;
            case METHOD_IM_RECORD_START:
                if (sessionInteractor != null) {
                    sessionInteractor.onStartRecording();
                }

                break;
            case METHOD_IM_RECORD_STOP:
                if (sessionInteractor != null) {
                    sessionInteractor.onStopRecording();
                }

                break;
            case METHOD_IM_RECORD_CANCEL:
                if (sessionInteractor != null) {
                    sessionInteractor.onCancelRecording();
                }

                break;
        }
    }

    /**
     * 初始化...
     * <p>
     * 由于 Android NIMSDK 必须在{@link Application#onCreate()}中初始化
     * 所以这里仅初始化自定义消息附件解析器，SDK的初始化还需放在在 Android 工程的 Application onCreate() 中
     */
    private void imInit() {
        FlutterNIMHelper.initIM(registrar.activity());
    }

    /**
     * IM登录
     */
    private void doIMLogin(String account, String token, final MethodChannel.Result result) {

        FlutterNIMHelper.getInstance().doIMLogin(account, token, new FlutterNIMHelper.IMLoginCallback() {
            @Override
            public void onResult(boolean isSuccess) {
                result.success(isSuccess);
            }
        });
    }

    /**
     * 开始聊天
     */
    private void startChat(String sessionId, final MethodChannel.Result result) {
        NIMSessionInteractor sessionInteractor = new NIMSessionInteractor(registrar.activity(), sessionId, eventSink);
        this.sessionInteractor = sessionInteractor;

        result.success(true);
    }
}
