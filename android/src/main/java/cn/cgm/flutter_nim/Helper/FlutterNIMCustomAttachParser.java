package cn.cgm.flutter_nim.Helper;

import com.netease.nimlib.sdk.msg.attachment.MsgAttachment;
import com.netease.nimlib.sdk.msg.attachment.MsgAttachmentParser;

/**
 * 自定义消息的附件解析器
 * <p/>
 *
 * @author chuguimin
 */
public class FlutterNIMCustomAttachParser implements MsgAttachmentParser {

    @Override
    public MsgAttachment parse(String json) {
        FlutterNIMCustomAttachment attachment = new FlutterNIMCustomAttachment();
        attachment.setCustomEncodeString(json);

        return attachment;
    }
}
