import 'nim_message_model.dart';
import 'nim_user_model.dart';

class NIMRecentSession {
  /// 会话Id，如果当前session为team，则sessionId为teamId，如果是P2P则为对方帐号
  String sessionId;

  /// 消息文本
  String messageContent;

  /// 未读消息数
  int unreadCount;

  /// 最后一条消息时间戳，单位 ms
  int timestamp;

  NIMUser userInfo;
  NIMMessage lastMessage;

  NIMRecentSession({
    this.sessionId,
    this.messageContent,
    this.unreadCount,
    this.timestamp,
    this.userInfo,
    this.lastMessage,
  });

  NIMRecentSession.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
    messageContent = json['messageContent'];
    unreadCount = json['unreadCount'];
    timestamp = json['timestamp'];

    userInfo =
        json['userInfo'] != null ? NIMUser.fromJson(json['userInfo']) : null;

    lastMessage = json['lastMessage'] != null
        ? NIMMessage.fromJson(json['lastMessage'])
        : null;
  }
}
