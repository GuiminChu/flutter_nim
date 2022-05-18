class NIMMessage {
  /// 消息来源
  String? from;

  /// 消息ID,唯一标识
  String? messageId;

  /// 消息发送时间戳，单位 ms
  int? timestamp;

  /// 消息文本
  /// 消息中除 NIMMessageTypeText 和 NIMMessageTypeTip 外，其他消息 text 字段都为 nil
  String? text;

  /// 是否是往外发的消息
  /// 由于能对自己发消息，所以并不是所有来源是自己的消息都是往外发的消息，这个字段用于判断头像排版位置（是左还是右）。
  bool? isOutgoingMsg;

  /// 是否显示时间戳
  bool? isShowTimeTag = false;

  NIMMessageType? messageType;
  NIMMessageObject? messageObject;
  NIMMessageDeliveryState? deliveryState;

  String? customMessageContent;
  dynamic customMessageObject;

  NIMMessage({
    this.from,
    this.messageId,
    this.timestamp,
    this.text,
    this.isOutgoingMsg,
    this.messageType,
    this.messageObject,
    this.deliveryState,
    this.customMessageContent,
  });

  NIMMessage.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    messageId = json['messageId'];
    timestamp = json['timestamp'];
    text = json['text'];
    isOutgoingMsg = json['isOutgoingMsg'];

    customMessageContent = json['customMessageContent'];

    messageObject = json['messageObject'] != null
        ? NIMMessageObject.fromJson(json['messageObject'])
        : null;

    // 消息类型
    // 原生传过来的是 rawValue，这里手动对应一下
    int messageTypeRawValue = json["messageType"];

    switch (messageTypeRawValue) {
      case 0:
        messageType = NIMMessageType.Text;
        break;
      case 1:
        messageType = NIMMessageType.Image;
        break;
      case 2:
        messageType = NIMMessageType.Audio;
        break;
      case 3:
        messageType = NIMMessageType.Video;
        break;
      case 4:
        messageType = NIMMessageType.Location;
        break;
      case 5:
        messageType = NIMMessageType.Notification;
        break;
      case 6:
        messageType = NIMMessageType.File;
        break;
      case 10:
        messageType = NIMMessageType.Tip;
        break;
      case 11:
        messageType = NIMMessageType.Robot;
        break;
      case 100:
        messageType = NIMMessageType.Custom;
        break;
    }

    // 发送状态
    // 原生传过来的是 rawValue，这里手动对应一下
    int deliveryStateRawValue = json["deliveryState"];

    switch (deliveryStateRawValue) {
      case 0:
        deliveryState = NIMMessageDeliveryState.Failed;
        break;
      case 1:
        deliveryState = NIMMessageDeliveryState.Delivering;
        break;
      case 2:
        deliveryState = NIMMessageDeliveryState.Delivered;
        break;
    }
  }
}

class NIMMessageObject {
  String? url;      // 图片、音频、视频的远程路径
  String? thumbUrl; // 图片缩略图远程路径
  String? thumbPath;// 图片缩略图本地路径
  String? coverUrl; // 视频封面图远程路径
  String? path;     // 音视频图片等文件本地路径
  int duration = 0; // 音频、视频的时长(毫秒)

  bool isPlayed = true; // 音频消息是否播放过

  // 图片或视频的宽高
  int width = 0;
  int height = 0;

  // 音频时长描述
  String get audioDurationDesc {
    int seconds = (duration / 1000).ceil();
    return "$seconds\"";
  }

  // 视频时长描述 分:秒
  String get videoDurationDesc {
    int seconds = (duration / 1000).round();

    int minute = (seconds - (seconds % 60)) ~/ 60;
    int second = (seconds - minute * 60);

    if (second > 9) {
      return "$minute:$second";
    } else {
      return "$minute:0$second";
    }
  }

  NIMMessageObject({
    this.url,
    this.thumbUrl,
    this.thumbPath,
    this.coverUrl,
    this.path,
    this.duration: 0,
    this.isPlayed: true,
    this.width: 0,
    this.height: 0,
  });

  NIMMessageObject.fromJson(Map<String, dynamic> json) {
    url = json['url'] ?? "";
    thumbUrl = json['thumbUrl'] ?? "";
    thumbPath = json['thumbPath'] ?? "";
    coverUrl = json['coverUrl'] ?? "";
    path = json['path'] ?? "";
    duration = json['duration'] ?? 0;
    isPlayed = json['isPlayed'] ?? true;
    width = json['width'] ?? 0;
    height = json['height'] ?? 0;
  }
}

/// 消息内容类型枚举
enum NIMMessageType {
  Text, // 文本类型消息 0
  Image, // 图片类型消息 1
  Audio, // 声音类型消息 2
  Video, // 视频类型消息 3
  Location, // 位置类型消息 4
  Notification, // 通知类型消息 5
  File, // 文件类型消息 6
  Tip, // 提醒类型消息 10
  Robot, // 机器人类型消息 11
  Custom, // 自定义类型消息 100
}

/// 消息投递状态（仅针对发送的消息）
enum NIMMessageDeliveryState {
  Failed, // 消息发送失败 0
  Delivering, // 消息发送中 1
  Delivered, // 消息发送成功 2
}
