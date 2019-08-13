package cn.cgm.flutter_nim.Helper;

import com.netease.nimlib.sdk.msg.attachment.MsgAttachment;

/**
 * 自定义消息的附件
 * <p/>
 *
 * @author chuguimin
 */
class FlutterNIMCustomAttachment implements MsgAttachment {
    private String customEncodeString;

    void setCustomEncodeString(String customEncodeString) {
        this.customEncodeString = customEncodeString;
    }

    @Override
    public String toJson(boolean send) {
        return customEncodeString;
    }

}
