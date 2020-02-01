enum NIMKickReason {
  /// 被另外一个客户端踢下线 (互斥客户端一端登录挤掉上一个登录中的客户端)
  byClient,

  /// 被服务器踢下线
  byServer,

  /// 被另外一个客户端手动选择踢下线
  byClientManually,
}
