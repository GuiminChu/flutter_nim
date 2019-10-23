import 'dart:io';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  bool _isEditing = false;
  bool _isShowAudioRecorder = false;
  bool _isShowStickerPanel = false;
  bool _isShowActionPanel = false;
  bool _isShowSendButton = false;

  bool get isEditing => _isEditing;

  bool get isShowAudioRecorder => _isShowAudioRecorder;

  bool get isShowStickerPanel => _isShowStickerPanel;

  bool get isShowActionPanel => _isShowActionPanel;

  bool get isShowSendButton {
    if (Platform.isIOS) {
      return false;
    } else {
      if (_isShowAudioRecorder || _isShowActionPanel) {
        return false;
      } else {
        return _isShowSendButton;
      }
    }
  }

  set isShowSendButton(bool value) {
    _isShowSendButton = value;

    notifyListeners();
  }

  // 是否在录音
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  set isRecording(bool value) {
    _isRecording = value;

    notifyListeners();
  }

  // 是否上滑取消发送录音
  bool _willCancelRecording = false;

  get willCancelRecording => _willCancelRecording;

  set willCancelRecording(bool value) {
    _willCancelRecording = value;

    notifyListeners();
  }

  // 是否快速点击
  bool isQuickTap = false;

  void beginEditing() {
    _isEditing = true;

    _isShowAudioRecorder = false;

    hideAllPanels();

    notifyListeners();
  }

  void endEditing() {
    _isEditing = false;
  }

  void willShowAudioRecorder() {
    _isShowAudioRecorder = true;
    _isShowStickerPanel = false;
    _isShowActionPanel = false;
  }

  void showAudioRecorder() {
//    _isShowAudioRecorder = true;

//    hideAllPanels();

    notifyListeners();
  }

  void willShowStickerPanel() {
    _isShowAudioRecorder = false;

    _isShowActionPanel = false;
    _isShowStickerPanel = true;
  }

  void showStickerPanel() {
    notifyListeners();
  }

  void willShowActionPanel() {
    _isShowAudioRecorder = false;

    _isShowStickerPanel = false;
    _isShowActionPanel = true;
  }

  void showActionPanel() {
    notifyListeners();
  }

  void hideAllPanels() {
    _isShowStickerPanel = false;
    _isShowActionPanel = false;

    notifyListeners();
  }
}
