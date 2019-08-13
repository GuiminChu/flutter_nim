package cn.cgm.flutter_nim.Helper;

import android.content.Context;
import android.media.MediaPlayer;
import android.net.Uri;
import android.text.TextUtils;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.Observer;
import com.netease.nimlib.sdk.RequestCallbackWrapper;
import com.netease.nimlib.sdk.media.record.AudioRecorder;
import com.netease.nimlib.sdk.media.record.IAudioRecordCallback;
import com.netease.nimlib.sdk.media.record.RecordType;
import com.netease.nimlib.sdk.msg.MessageBuilder;
import com.netease.nimlib.sdk.msg.MsgService;
import com.netease.nimlib.sdk.msg.MsgServiceObserve;
import com.netease.nimlib.sdk.msg.constant.MsgStatusEnum;
import com.netease.nimlib.sdk.msg.constant.SessionTypeEnum;
import com.netease.nimlib.sdk.msg.model.IMMessage;
import com.netease.nimlib.sdk.msg.model.QueryDirectionEnum;
import com.netease.nimlib.sdk.msg.model.RecentContact;
import com.netease.nimlib.sdk.uinfo.UserService;
import com.netease.nimlib.sdk.uinfo.model.NimUserInfo;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import io.flutter.plugin.common.EventChannel.EventSink;

public class NIMSessionInteractor implements IAudioRecordCallback {
    private Context context;

    private EventSink eventSink;

    private List<RecentContact> recentSessions = new ArrayList<>();

    private String sessionId;
    private List<IMMessage> allMessages = new ArrayList<>();

    // 语音
    private AudioRecorder audioMessageHelper;

    public NIMSessionInteractor(Context context, String sessionId, EventSink eventSink) {
        this.context = context;
        this.sessionId = sessionId;
        this.eventSink = eventSink;

        registerObservers(true);

        initAudioRecord();

        getUserInfo();
    }

    private void registerObservers(boolean register) {
        MsgServiceObserve service = NIMClient.getService(MsgServiceObserve.class);

        service.observeReceiveMessage(incomingMessageObserver, register);

        service.observeMsgStatus(statusObserver, register);

        service.observeRecentContact(recentContactsObserver, register);
        service.observeRecentContactDeleted(recentContactDeletedObserver, register);

        // 已读回执监听
//        if (NimUIKitImpl.getOptions().shouldHandleReceipt) {
//            service.observeMessageReceipt(messageReceiptObserver, register);
//        }


        // 设置当前正在聊天的对象。设置后会影响内建的消息提醒。如果有新消息到达，且消息来源是正在聊天的对象，将不会有消息提醒。
        // 调用该接口还会附带调用{@link #clearUnreadCount(String, SessionTypeEnum)},将正在聊天对象的未读数清零。
        NIMClient.getService(MsgService.class).setChattingAccount(sessionId, SessionTypeEnum.P2P);
    }

    private void unregisterObservers() {
        registerObservers(false);

        // 目前没有与任何人对话，需要状态栏消息通知
        NIMClient.getService(MsgService.class).setChattingAccount(MsgService.MSG_CHATTING_ACCOUNT_NONE, SessionTypeEnum.None);
    }

    // 如果本地没有用户资料，去服务端同步一下
    private void getUserInfo() {
        NimUserInfo user = NIMClient.getService(UserService.class).getUserInfo(sessionId);
        if (user == null) {
            List<String> userIds = Arrays.asList(sessionId);
            NIMClient.getService(UserService.class).fetchUserInfo(userIds);
        }
    }

    public void onDestroy() {
        unregisterObservers();

        // release
        if (audioMessageHelper != null) {
            audioMessageHelper.destroyAudioRecorder();
        }
    }

    /**
     * **************************** 发送消息 ***********************************
     */


    public void sendTextMessage(String text) {
        // 创建一个文本消息
        IMMessage textMessage = MessageBuilder.createTextMessage(sessionId, SessionTypeEnum.P2P, text);
        // 发送给对方
        sendMessage(textMessage, false);
    }

    public void sendImageMessage(String imagePath) {
        // 图片文件
        File file = new File(imagePath);
        // 创建一个图片消息
        IMMessage imageMessage = MessageBuilder.createImageMessage(sessionId, SessionTypeEnum.P2P, file, file.getName());
        // 发送给对方
        sendMessage(imageMessage, false);
    }

    public void sendVideoMessage(String videoPath) {
        // 视频文件
        File file = new File(videoPath);
        // 获取视频mediaPlayer
        MediaPlayer mediaPlayer = getVideoMediaPlayer(file);
        // 视频文件持续时间
        long duration = mediaPlayer == null ? 0 : mediaPlayer.getDuration();
        // 视频高度
        int height = mediaPlayer == null ? 0 : mediaPlayer.getVideoHeight();
        // 视频宽度
        int width = mediaPlayer == null ? 0 : mediaPlayer.getVideoWidth();
        // 创建视频消息
        IMMessage videoMessage = MessageBuilder.createVideoMessage(sessionId, SessionTypeEnum.P2P, file, duration, width, height, null);
        // 发送给对方
        sendMessage(videoMessage, false);
    }

    public void sendAudioMessage(String audioPath) {
        // 音频文件
        File audioFile = new File(audioPath);
        // 创建音频消息
        // TODO: 获取时长
        IMMessage audioMessage = MessageBuilder.createAudioMessage(sessionId, SessionTypeEnum.P2P, audioFile, 10);
        // 发送给对方
        sendMessage(audioMessage, false);
    }

    public void sendCustomMessage(String customEncodeString, String apnsContent) {
        FlutterNIMCustomAttachment attachment = new FlutterNIMCustomAttachment();
        attachment.setCustomEncodeString(customEncodeString);

        IMMessage message = MessageBuilder.createCustomMessage(sessionId, SessionTypeEnum.P2P, apnsContent, attachment);
        sendMessage(message, false);
    }

    public static void sendCustomMessageToSession(String sessionID, String customEncodeString, String apnsContent) {
        FlutterNIMCustomAttachment attachment = new FlutterNIMCustomAttachment();
        attachment.setCustomEncodeString(customEncodeString);

        IMMessage message = MessageBuilder.createCustomMessage(sessionID, SessionTypeEnum.P2P, apnsContent, attachment);
        NIMClient.getService(MsgService.class).sendMessage(message, true);
    }

    public void resendMessage(String messageId) {
        IMMessage message = null;
        for (IMMessage msg : allMessages) {
            if (msg.getUuid().equalsIgnoreCase(messageId)) {
                message = msg;
                break;
            }
        }

        if (message != null) {
            sendMessage(message, true);
        }
    }

    private void sendMessage(IMMessage message, boolean resend) {
        NIMClient.getService(MsgService.class).sendMessage(message, resend);

        if (message.getSessionId().equalsIgnoreCase(sessionId)) {
            // 用来判断是否是发送失败重发
            boolean hasThisMessage = false;

            for (int i = 0; i < allMessages.size(); i++) {
                if (allMessages.get(i).getUuid().equalsIgnoreCase(message.getUuid())) {
                    hasThisMessage = true;
                    break;
                }
            }

            if (!hasThisMessage) {
                allMessages.add(message);
            }

            refreshDataSource();
        }

    }

    public void markAudioMessageRead(String messageId) {
        IMMessage message = null;
        for (IMMessage msg : allMessages) {
            if (msg.getUuid().equalsIgnoreCase(messageId)) {
                message = msg;
                break;
            }
        }

        if (message != null) {
            // 将未读标识去掉,更新本地数据库
            if (NIMSessionParser.isUnreadAudioMessage(message)) {
                message.setStatus(MsgStatusEnum.read);
                NIMClient.getService(MsgService.class).updateIMMessageStatus(message);
            }
        }
    }


    /**
     * 监听消息状态变化
     * 这个接口可以监听消息接收或发送状态 MsgStatusEnum 和 消息附件接收或发送状态 AttachStatusEnum 的变化。
     * 当状态更改为 AttachStatusEnum.transferred 表示附件下载成功。
     */
    private Observer<IMMessage> statusObserver = new Observer<IMMessage>() {
        @Override
        public void onEvent(IMMessage message) {
            // 根据sessionId判断是否是自己的消息
            if (message.getSessionId().equalsIgnoreCase(sessionId)) {

                for (int i = 0; i < allMessages.size(); i++) {
                    if (allMessages.get(i).getUuid().equalsIgnoreCase(message.getUuid())) {
                        allMessages.set(i, message);
                        break;
                    }
                }

                refreshDataSource();
            }
        }
    };


    /**
     * 最近联系人列表变化观察者
     */
    private Observer<List<RecentContact>> recentContactsObserver = new Observer<List<RecentContact>>() {
        @Override
        public void onEvent(List<RecentContact> recentContacts) {
            onRecentContactChanged(recentContacts);
        }
    };

    private void onRecentContactChanged(List<RecentContact> recentContacts) {
        int index;
        for (RecentContact r : recentContacts) {
            index = -1;
            for (int i = 0; i < recentSessions.size(); i++) {
                if (r.getContactId().equals(recentSessions.get(i).getContactId())
                        && r.getSessionType() == (recentSessions.get(i).getSessionType())) {
                    index = i;
                    break;
                }
            }

            if (index >= 0) {
                recentSessions.remove(index);
            }

            recentSessions.add(r);
        }

        refreshMessages();
    }

    private Observer<RecentContact> recentContactDeletedObserver = new Observer<RecentContact>() {
        @Override
        public void onEvent(RecentContact recentContact) {
            if (recentContact != null) {
                for (RecentContact item : recentSessions) {
                    if (TextUtils.equals(item.getContactId(), recentContact.getContactId())
                            && item.getSessionType() == recentContact.getSessionType()) {
                        recentSessions.remove(item);
                        refreshMessages();
                        break;
                    }
                }
            } else {
                recentSessions.clear();
                refreshMessages();
            }
        }
    };


    private void refreshMessages() {
        sortRecentContacts(recentSessions);
    }

    /**
     * 消息接收观察者
     */
    private Observer<List<IMMessage>> incomingMessageObserver = new Observer<List<IMMessage>>() {
        @Override
        public void onEvent(List<IMMessage> imMessages) {
            onMessageIncoming(imMessages);
        }
    };

    private void onMessageIncoming(List<IMMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return;
        }

        allMessages.add(messages.get(0));

        refreshDataSource();

        // 发送已读回执
//        messageListPanel.sendReceipt();
    }

    public void loadHistoryMessages(int messageIndex) {
        IMMessage message;
        if (messageIndex >= 0) {
            message = this.allMessages.get(messageIndex);
        } else {
            message = MessageBuilder.createEmptyMessage(sessionId, SessionTypeEnum.P2P, 0);
        }

        NIMClient.getService(MsgService.class)
                .queryMessageListEx(message, QueryDirectionEnum.QUERY_OLD, 20, true)
                .setCallback(new RequestCallbackWrapper<List<IMMessage>>() {
                    @Override
                    public void onResult(int code, List<IMMessage> result, Throwable exception) {

                        if (result != null) {
                            allMessages.addAll(0, result);

                            refreshDataSource();
                        }
                    }
                });
    }

    private void refreshDataSource() {
        // 主动给 flutter 发消息
        if (eventSink != null) {
            eventSink.success(NIMSessionParser.handleMessages(allMessages));
        }
    }


    /**
     * 获取视频mediaPlayer
     *
     * @param file 视频文件
     * @return mediaPlayer
     */
    private MediaPlayer getVideoMediaPlayer(File file) {
        try {
            return MediaPlayer.create(context, Uri.fromFile(file));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * **************************** 排序 ***********************************
     */

    // 置顶功能可直接使用，也可作为思路，供开发者充分利用RecentContact的tag字段
    // 联系人置顶tag
    private final long RECENT_TAG_STICKY = 0x0000000000000001;

    private void sortRecentContacts(List<RecentContact> list) {
        if (list.size() == 0) {
            return;
        }
        Collections.sort(list, comp);
    }

    private Comparator<RecentContact> comp = new Comparator<RecentContact>() {

        @Override
        public int compare(RecentContact o1, RecentContact o2) {
            // 先比较置顶tag
            long sticky = (o1.getTag() & RECENT_TAG_STICKY) - (o2.getTag() & RECENT_TAG_STICKY);
            if (sticky != 0) {
                return sticky > 0 ? -1 : 1;
            } else {
                long time = o1.getTime() - o2.getTime();
                return time == 0 ? 0 : (time > 0 ? -1 : 1);
            }
        }
    };

    /** *************************** 音频相关 ************************************/

    /**
     * 初始化AudioRecord
     */
    private void initAudioRecord() {
        if (audioMessageHelper == null) {
            audioMessageHelper = new AudioRecorder(context, RecordType.AAC, 120, this);
        }
    }

    /**
     * 开始语音录制
     */
    public void onStartRecording() {
        audioMessageHelper.startRecord();
    }

    /**
     * 结束语音录制
     */
    public void onStopRecording() {
        audioMessageHelper.completeRecord(false);
    }

    /**
     * 取消语音录制
     */
    public void onCancelRecording() {
        audioMessageHelper.completeRecord(true);
    }

    /// 以下回调

    /**
     * 录音器已就绪，提供此接口用于在录音前关闭本地音视频播放（可选）
     */
    @Override
    public void onRecordReady() {

    }

    /**
     * 开始录音回调
     *
     * @param audioFile  录音文件
     * @param recordType 文件类型
     */
    @Override
    public void onRecordStart(File audioFile, RecordType recordType) {
    }

    /**
     * 录音结束，成功
     *
     * @param audioFile   录音文件
     * @param audioLength 录音时间长度 ms
     * @param recordType  文件类型
     */
    @Override
    public void onRecordSuccess(File audioFile, long audioLength, RecordType recordType) {
        // Logger.e("录音完成");
        if (audioLength > 1000) {
            // 创建音频消息
            IMMessage audioMessage = MessageBuilder.createAudioMessage(sessionId, SessionTypeEnum.P2P, audioFile, audioLength);
            // 发送给对方
            sendMessage(audioMessage, false);
        } else {
            // TODO:
            // 说话时间太短
        }
    }

    /**
     * 录音结束，出错
     */
    @Override
    public void onRecordFail() {

    }

    /**
     * 录音结束， 用户主动取消录音
     */
    @Override
    public void onRecordCancel() {
    }

    /**
     * 到达指定的最长录音时间
     *
     * @param maxTime 录音文件时间长度限制
     */
    @Override
    public void onRecordReachedMaxTime(int maxTime) {

    }
}
