import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nim/flutter_nim.dart';

class NIMProvider with ChangeNotifier {
  // 会话消息未读数
  int _badgeNumber = 0;

  // 最近会话列表
  List<NIMRecentSession> _recentSessions = [];

  // 单个会话消息相关
  List<NIMMessage> _messages = [];
  bool _hasMoreData = false;

  int get badgeNumber => _badgeNumber;

  List<NIMRecentSession> get recentSessions => _recentSessions;

  List<NIMMessage> get messages => _messages;

  bool get hasMoreData => _hasMoreData;

  NIMProvider() {
    FlutterNIM().loadRecentSessions();

    FlutterNIM().recentSessionsResponse.listen((recentSessions) {
      this._recentSessions = recentSessions;

      this._badgeNumber = recentSessions
          .map((s) => s.unreadCount)
          .fold(0, (curr, next) => curr + next);

      notifyListeners();
    });

    FlutterNIM().messagesResponse.listen((messages) {
      this._messages = messages.reversed.toList();

      // 求余，如果结果等于零则可能还有更多数据
      int remainder = this._messages.length % 20;

      _hasMoreData = remainder == 0;

      notifyListeners();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
