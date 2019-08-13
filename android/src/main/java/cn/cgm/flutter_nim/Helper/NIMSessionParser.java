package cn.cgm.flutter_nim.Helper;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.msg.MsgService;
import com.netease.nimlib.sdk.msg.attachment.AudioAttachment;
import com.netease.nimlib.sdk.msg.attachment.ImageAttachment;
import com.netease.nimlib.sdk.msg.attachment.VideoAttachment;
import com.netease.nimlib.sdk.msg.constant.AttachStatusEnum;
import com.netease.nimlib.sdk.msg.constant.MsgDirectionEnum;
import com.netease.nimlib.sdk.msg.constant.MsgStatusEnum;
import com.netease.nimlib.sdk.msg.constant.MsgTypeEnum;
import com.netease.nimlib.sdk.msg.model.IMMessage;
import com.netease.nimlib.sdk.msg.model.RecentContact;
import com.netease.nimlib.sdk.uinfo.UserService;
import com.netease.nimlib.sdk.uinfo.model.NimUserInfo;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

class NIMSessionParser {

    // 处理最近会话数据
    static String handleRecentSessionsData(List<RecentContact> recents) {
        String result = "";

        if (recents != null) {
            JSONArray recentSessionJSONArray = new JSONArray();

            for (int i = 0; i < recents.size(); i++) {
                RecentContact recent = recents.get(i);

                // 最近联系人ID
                String contactId = recent.getContactId();

                JSONObject recentObject = new JSONObject();
                try {
                    recentObject.put("sessionId", recent.getContactId());
                    recentObject.put("unreadCount", recent.getUnreadCount());
                    recentObject.put("timestamp", recent.getTime());
                    recentObject.put("messageContent", getDefaultDigest(recent));

                    // 最后一条消息信息
                    JSONObject lastMessageObject = new JSONObject();

                    lastMessageObject.put("messageId", recent.getRecentMessageId());
                    lastMessageObject.put("from", recent.getFromAccount());
                    lastMessageObject.put("text", recent.getContent());
                    lastMessageObject.put("messageType", recent.getMsgType().getValue());
                    lastMessageObject.put("timestamp", recent.getTime());

                    if (recent.getMsgType() == MsgTypeEnum.custom) {
                        FlutterNIMCustomAttachment customAttachment = (FlutterNIMCustomAttachment) recent.getAttachment();
                        lastMessageObject.put("customMessageContent", customAttachment.toJson(false));
                    }

                    switch (recent.getMsgStatus()) {
                        case fail:
                            lastMessageObject.put("deliveryState", 0);
                            break;
                        case sending:
                            lastMessageObject.put("deliveryState", 1);
                            break;
                        case success:
                            lastMessageObject.put("deliveryState", 2);
                            break;
                        default:
                            break;
                    }
                    recentObject.put("lastMessage", lastMessageObject);

                    // 用户信息
                    JSONObject userObject = new JSONObject();
                    NimUserInfo userInfo = NIMClient.getService(UserService.class).getUserInfo(contactId);
                    if (userInfo != null) {
                        userObject.put("nickname", userInfo.getName());
                        userObject.put("avatarUrl", userInfo.getAvatar());
                        userObject.put("userExt", userInfo.getExtension());
                    }
                    recentObject.put("userInfo", userObject);

                    recentSessionJSONArray.put(recentObject);
                } catch (JSONException exception) {
                    exception.printStackTrace();
                }
            }

            JSONObject imObject = new JSONObject();

            try {
                imObject.put("recentSessions", recentSessionJSONArray);
            } catch (JSONException exception) {
                exception.printStackTrace();
            }

            result = imObject.toString();

            return result;
        }

        return result;
    }

    // 处理会话消息数据
    static String handleMessages(List<IMMessage> messages) {
        String result = "";

        if (messages != null) {
            JSONArray messageJSONArray = new JSONArray();

            for (int i = 0; i < messages.size(); i++) {
                IMMessage message = messages.get(i);
                messageJSONArray.put(getMessageJSONObject(message));
            }

            JSONObject imObject = new JSONObject();

            try {
                imObject.put("messages", messageJSONArray);
            } catch (JSONException exception) {
                exception.printStackTrace();
            }

            result = imObject.toString();

            return result;
        }

        return result;
    }

    // 可用的消息对象
    private static JSONObject getMessageJSONObject(IMMessage message) {
        JSONObject object = new JSONObject();

        try {
            object.put("messageId", message.getUuid());
            object.put("from", message.getFromAccount());
            object.put("text", message.getContent());
            object.put("messageType", message.getMsgType().getValue());
            object.put("timestamp", message.getTime());

            // 为了与 iOS 端兼容，做特殊处理

            switch (message.getDirect()) {
                case In:
                    object.put("isOutgoingMsg", false);
                    break;
                case Out:
                    object.put("isOutgoingMsg", true);
                    break;
            }

            switch (message.getStatus()) {
                case fail:
                    object.put("deliveryState", 0);
                    break;
                case sending:
                    object.put("deliveryState", 1);
                    break;
                case success:
                    object.put("deliveryState", 2);
                    break;
                default:
                    break;
            }

            switch (message.getMsgType()) {
                case image:
                    ImageAttachment imageAttachment = (ImageAttachment) message.getAttachment();

                    JSONObject imageObject = new JSONObject();
                    imageObject.put("url", imageAttachment.getUrl());
                    imageObject.put("thumbUrl", imageAttachment.getThumbUrl());
                    imageObject.put("thumbPath", imageAttachment.getThumbPath());
                    imageObject.put("path", imageAttachment.getPath());
                    imageObject.put("width", imageAttachment.getWidth());
                    imageObject.put("height", imageAttachment.getHeight());

                    object.put("messageObject", imageObject);

                    break;
                case audio:
                    AudioAttachment audioAttachment = (AudioAttachment) message.getAttachment();

                    JSONObject audioObject = new JSONObject();
                    audioObject.put("url", audioAttachment.getUrl());
                    audioObject.put("path", audioAttachment.getPath());
                    audioObject.put("duration", audioAttachment.getDuration());
                    audioObject.put("isPlayed", !NIMSessionParser.isUnreadAudioMessage(message));

                    object.put("messageObject", audioObject);

                    break;
                case video:
                    VideoAttachment videoAttachment = (VideoAttachment) message.getAttachment();

                    JSONObject videoObject = new JSONObject();
                    videoObject.put("url", videoAttachment.getUrl());
                    videoObject.put("coverUrl", videoAttachment.getThumbUrl());
                    videoObject.put("path", videoAttachment.getPath());
                    videoObject.put("duration", videoAttachment.getDuration());
                    videoObject.put("width", videoAttachment.getWidth());
                    videoObject.put("height", videoAttachment.getHeight());

                    object.put("messageObject", videoObject);

                    break;
                case custom:
                    FlutterNIMCustomAttachment customAttachment = (FlutterNIMCustomAttachment) message.getAttachment();
                    object.put("customMessageContent", customAttachment.toJson(false));

                    break;
                default:
                    break;
            }

        } catch (JSONException exception) {
            exception.printStackTrace();
        }

        return object;
    }

    private static String getUserExt(String account) {
        NimUserInfo user = NIMClient.getService(UserService.class).getUserInfo(account);
        if (user == null || user.getExtension() == null) {
            return "";
        } else {
            return user.getExtension();
        }
    }

    /**
     * @param account 用户帐号
     * @return 用户名
     */
    private static String getUserDisplayName(String account) {

        NimUserInfo user = NIMClient.getService(UserService.class).getUserInfo(account);
        if (user == null) {
            return "买家";
        } else {
            return user.getName();
        }
    }

    /**
     * @param account 用户帐号
     * @return 用户头像链接地址
     */
    private static String getUserAvatar(String account) {

        NimUserInfo user = NIMClient.getService(UserService.class).getUserInfo(account);
        if (user != null) {
            return user.getAvatar();
        } else {
            return null;
        }
    }

    /**
     * 最近联系人列表项文案定制
     *
     * @param recent 最近联系人
     * @return 默认文案
     */
    private static String getDefaultDigest(RecentContact recent) {
        switch (recent.getMsgType()) {
            case text:
                return recent.getContent();
            case image:
                return "[图片]";
            case video:
                return "[视频]";
            case audio:
                return "[语音消息]";
            case location:
                return "[位置]";
            case file:
                return "[文件]";
            case tip:
                List<String> uuids = new ArrayList<>();
                uuids.add(recent.getRecentMessageId());
                List<IMMessage> messages = NIMClient.getService(MsgService.class).queryMessageListByUuidBlock(uuids);
                if (messages != null && messages.size() > 0) {
                    return messages.get(0).getContent();
                }
                return "[通知提醒]";
            case notification:
                return "[通知消息]";
            case robot:
                return "[机器人消息]";
            case custom:
                return "[自定义消息]";
            default:
                return "[自定义消息]";
        }
    }

    static boolean isUnreadAudioMessage(IMMessage message) {
        if ((message.getMsgType() == MsgTypeEnum.audio)
                && message.getDirect() == MsgDirectionEnum.In
                && message.getAttachStatus() == AttachStatusEnum.transferred
                && message.getStatus() != MsgStatusEnum.read) {
            return true;
        } else {
            return false;
        }
    }

}
