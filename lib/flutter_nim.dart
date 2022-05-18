//
//  flutter_nim.dart
//  flutter_nim
//
//  Created by GuiminChu on 2019/7/19.
//
//  Copyright (c) 2019 GuiminChu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/nim_session_model.dart';
import 'models/nim_message_model.dart';
import 'models/nim_kick_reason.dart';

export 'models/nim_session_model.dart';
export 'models/nim_message_model.dart';
export 'models/nim_user_model.dart';
export 'models/nim_kick_reason.dart';

class FlutterNIM {
  static FlutterNIM? _instance;

  factory FlutterNIM() {
    if (_instance == null) {
      final MethodChannel methodChannel =
          const MethodChannel("flutter_nim_method");
      final EventChannel eventChannel = const EventChannel('flutter_nim_event');

      _instance = FlutterNIM._private(methodChannel, eventChannel);
    }
    return _instance!;
  }

  FlutterNIM._private(this._methodChannel, this._eventChannel) {
    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  StreamController<List<NIMRecentSession>> _recentSessionsController =
      StreamController.broadcast();

  StreamController<List<NIMMessage>> _messagesController =
      StreamController.broadcast();

  StreamController<NIMKickReason> _kickReasonController =
      StreamController.broadcast();

  /// Response for recent sessions
  Stream<List<NIMRecentSession>> get recentSessionsResponse =>
      _recentSessionsController.stream;

  /// Response for chat messages
  Stream<List<NIMMessage>> get messagesResponse => _messagesController.stream;

  /// Response for kick reason
  Stream<NIMKickReason> get kickReasonResponse => _kickReasonController.stream;

  Future<String> get platformVersion async {
    final String version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 初始化
  ///
  /// [appKey]必须要传
  /// 如果[imAccount]和[imToken]不为空，则会调用云信[autoLogin]方法
  Future<void> init({
    String appKey = "",
    String apnsCername = "",
    String apnsCernameDevelop = "",
    String xmAppId = "",
    String xmAppKey = "",
    String xmCertificateName = "",
    String hwCertificateName = "",
    String vivoCertificateName = "",
    String imAccount = "",
    String imToken = "",
  }) async {
    await _methodChannel.invokeMethod("imInit", {
      "appKey": appKey,
      "apnsCername": apnsCername,
      "apnsCernameDevelop": apnsCernameDevelop,
      "xmAppId": xmAppId,
      "xmAppKey": xmAppKey,
      "xmCertificateName": xmCertificateName,
      "hwCertificateName": hwCertificateName,
      "vivoCertificateName": vivoCertificateName,
      "imAccount": imAccount,
      "imToken": imToken,
    });
  }

  /// IM 登录
  Future<bool> login(String imAccount, String imToken) async {
    Map<String, String> map = {
      "imAccount": imAccount,
      "imToken": imToken,
    };

    final bool isLoginSuccess =
        await _methodChannel.invokeMethod("imLogin", map);
    return isLoginSuccess;
  }

  /// IM 退出登录
  Future<void> logout() async {
    await _methodChannel.invokeMethod("imLogout");
  }

  /// 获取会话列表
  Future<void> loadRecentSessions() async {
    await _methodChannel.invokeMethod("imRecentSessions");
  }

  /// 删除某项最近会话
  Future<void> deleteRecentSession(String sessionId) async {
    Map<String, String> map = {
      "sessionId": sessionId,
    };

    await _methodChannel.invokeMethod("imDeleteRecentSession", map);
  }

  /// 开始会话
  Future<bool> startChat(String sessionId) async {
    Map<String, String> map = {
      "sessionId": sessionId,
    };

    final bool isSuccess =
        await _methodChannel.invokeMethod("imStartChat", map);
    return isSuccess;
  }

  Future<void> exitChat() async {
    await _methodChannel.invokeMethod("imExitChat");
  }

  /// 获取会话消息
  ///
  /// [messageIndex] 传[-1]时返回最新的20条消息列表。
  /// 加载更多时传最上面那条消息的[index]
  Future<void> loadMessages(int messageIndex) async {
    Map<String, int> map = {
      "messageIndex": messageIndex,
    };

    await _methodChannel.invokeMethod('imMessages', map);
  }

  /// 会话内发送文本消息
  Future<void> sendText(String text) async {
    Map<String, String> map = {
      "text": text ?? "",
    };

    await _methodChannel.invokeMethod("imSendText", map);
  }

  /// 会话内发送图片消息
  Future<void> sendImage(String imagePath) async {
    Map<String, String> map = {
      "imagePath": imagePath ?? "",
    };

    await _methodChannel.invokeMethod("imSendImage", map);
  }

  /// 会话内发送视频消息
  Future<void> sendVideo(String videoPath) async {
    Map<String, String> map = {
      "videoPath": videoPath ?? "",
    };

    await _methodChannel.invokeMethod("imSendVideo", map);
  }

  /// 会话内发送音频消息
  Future<void> sendAudio(String audioPath) async {
    Map<String, String> map = {
      "audioPath": audioPath ?? "",
    };

    await _methodChannel.invokeMethod("imSendAudio", map);
  }

  /// 会话内发送自定义消息
  Future<void> sendCustomMessage(Map customObject,
      {String? apnsContent}) async {
    final String customEncodeString = json.encode(customObject);

    Map<String, String> map = {
      "customEncodeString": customEncodeString,
      "apnsContent": apnsContent ?? "[自定义消息]",
    };

    await _methodChannel.invokeMethod("imSendCustom", map);
  }

  /// 会话外发送自定义消息
  Future<bool> sendCustomMessageToSession(String sessionId, Map customObject,
      {String? apnsContent}) async {
    final String customEncodeString = json.encode(customObject);

    Map<String, String> map = {
      "sessionId": sessionId,
      "customEncodeString": customEncodeString,
      "apnsContent": apnsContent ?? "[自定义消息]",
    };
    final bool isSendSuccess =
        await _methodChannel.invokeMethod("imSendCustomToSession", map);
    return isSendSuccess;
  }

  /// 会话内重发消息
  Future<void> resendMessage(String messageId) async {
    Map<String, String> map = {
      "messageId": messageId ?? "",
    };

    await _methodChannel.invokeMethod("imResendMessage", map);
  }

  /// iOS 和 Android 均使用了 NIMSDK 中的录音功能
  ///
  /// 开始录音
  Future<void> onStartRecording() async {
    await _methodChannel.invokeMethod("onStartRecording");
  }

  /// 结束录音
  Future<void> onStopRecording() async {
    await _methodChannel.invokeMethod("onStopRecording");
  }

  /// 取消录音
  Future<void> onCancelRecording() async {
    await _methodChannel.invokeMethod("onCancelRecording");
  }

  /// 标记音频已读
  Future<void> markAudioMessageRead(String messageId) async {
    Map<String, String> map = {
      "messageId": messageId,
    };

    await _methodChannel.invokeMethod("imMarkAudioMessageRead", map);
  }

  //////////////

  // 解析最近会话 JSON
  void _parseRecentSessionsData(dynamic imMap) {
    final recentSessionsMap = imMap["recentSessions"];

    if (recentSessionsMap != null) {
      List<NIMRecentSession> recentSessions = recentSessionsMap
          .map<NIMRecentSession>(
              (itemJson) => NIMRecentSession.fromJson(itemJson))
          .toList();

      _recentSessionsController.add(recentSessions);
    }
  }

  // 解析聊天记录 JSON
  void _parseMessagesData(dynamic imMap) {
    final messagesMap = imMap["messages"];

    if (messagesMap != null) {
      List<NIMMessage> messages = messagesMap
          .map<NIMMessage>((itemJson) => NIMMessage.fromJson(itemJson))
          .toList();

      if (messages.isNotEmpty) {
        List.generate(messages.length, (index) {
          if (index == 0) {
            messages[index].isShowTimeTag = true;
          } else {
            // 两条消息相隔 300 秒则显示时间戳
            if (messages[index].timestamp! - messages[index - 1].timestamp! >
                300000) {
              messages[index].isShowTimeTag = true;
            }
          }
        });
      }

      _messagesController.add(messages);
    }
  }

  // 解析被踢下线 JSON
  void _parseKickReasonData(dynamic imMap) {
    final kickCode = imMap["kickCode"];

    if (kickCode != null) {
      if (kickCode == 1) {
        _kickReasonController.add(NIMKickReason.byClient);
      } else if (kickCode == 2) {
        _kickReasonController.add(NIMKickReason.byServer);
      } else if (kickCode == 3) {
        _kickReasonController.add(NIMKickReason.byClientManually);
      }
    }
  }

  void _onEvent(Object? event) {
    if (event != null && event is String) {
      String eventString = event;

      try {
        final imMap = json.decode(eventString);

        _parseRecentSessionsData(imMap);
        _parseMessagesData(imMap);
        _parseKickReasonData(imMap);
      } on FormatException catch (e) {
        print("FlutterNIM - That string didn't look like Json.");
        print(e.message);
      } on NoSuchMethodError catch (e) {
        print('FlutterNIM - That string was null!');
        print(e.toString());
      }
    }
  }

  // EventChannel 错误返回
  void _onError(Object error) {
    print("FlutterNIM - ${error.toString()}");
  }
}
