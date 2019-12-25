import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_nim/flutter_nim.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

import 'package:flutter_nim_example/provider/provider.dart';
import 'package:flutter_nim_example/zeus_kit/zeus_kit.dart';

///
const Color leftBubbleColor = Colors.white;

///
const Color rightBubbleColor = const Color(0xFFFFA800);

const rightBubbleGradient = LinearGradient(
  colors: [
    Color(0xFFFFC600),
    Color(0xFFFFA800),
  ],
);

class Chat extends StatelessWidget {
  final String sessionId;
  final String chatName;

  Chat({
    Key key,
    @required this.sessionId,
    this.chatName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>(
      create: (context) => ChatProvider(),
      child: ChatScreen(
        sessionId: sessionId,
        chatName: chatName,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String sessionId;
  final String chatName;

  ChatScreen({
    Key key,
    @required this.sessionId,
    this.chatName,
  }) : super(key: key);

  @override
  State createState() => _ChatScreenState(sessionId: sessionId);
}

class _ChatScreenState extends State<ChatScreen> {
  String sessionId;

  final ScrollController _listScrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ChatProvider _chatProvider;
  List<NIMMessage> messages = [];
  bool hasMoreData = false;

  // 语音播放器
  AudioPlayer _audioPlayer = AudioPlayer();

  // 记录当前播放的语音消息ID
  String _currentPlayingAudioId = "";

  FlutterNIM _nim = FlutterNIM();

  _ChatScreenState({
    Key key,
    @required this.sessionId,
  });

  @override
  void initState() {
    super.initState();

    // _focusNodeListeners();
    // _scrollControllerListeners();
    _playerStateListeners();

    _nim.loadMessages(-1);

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        if (visible) {
          _chatProvider.beginEditing();
        } else {
          _chatProvider.endEditing();

          if (_chatProvider.isShowActionPanel) {
            _chatProvider.showActionPanel();
          }

          if (_chatProvider.isShowAudioRecorder) {
            _chatProvider.showAudioRecorder();
          }
        }
      },
    );
  }

  // 有冲突，不用
  void _scrollControllerListeners() {
    _listScrollController.addListener(() {
      debugPrint("偏移: ${_listScrollController.offset}");

      if (_chatProvider.isEditing) {
        // 隐藏软键盘
        _focusNode.unfocus();
      }

      if (_chatProvider.isShowStickerPanel || _chatProvider.isShowActionPanel) {
        _chatProvider.hideAllPanels();
      }
    });
  }

  void _focusNodeListeners() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 获取焦点
//        debugPrint("获取焦点");
//        _chatProvider.beginEditing();
      } else {
        // 失去焦点
//        debugPrint("失去焦点");
//        _chatProvider.endEditing();
      }
    });
  }

  void _playerStateListeners() {
    _audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
      if (state == AudioPlayerState.COMPLETED ||
          state == AudioPlayerState.STOPPED) {
        _currentPlayingAudioId = "";
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Chat 刷新总 line 173");

    return Consumer2<NIMProvider, ChatProvider>(
      builder: (context, provider, chatProvider, _) {
        this.messages = provider.messages;
        this.hasMoreData = provider.hasMoreData;

        this._chatProvider = chatProvider;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.chatName ?? "",
            ),
            centerTitle: true,
            elevation: 0.5,
          ),
          body: _buildBodyWidget(),
        );
      },
    );
  }

  Widget _buildBodyWidget() {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _buildListView(),
              _buildInputBar(),

              // Sticker
              if (_chatProvider.isShowStickerPanel)
                _buildStickerPanel(),

              // Action panel
              if (_chatProvider.isShowActionPanel)
                _buildActionPanel(),
            ],
          ),
          // 正在录音
          Offstage(
            offstage: !_chatProvider.isRecording,
            child: Center(
              child: _buildRecordingDialog(),
            ),
          ),
        ],
      ),
    );
  }

//  Future<bool> onBackPress() {
//    if (isShowStickerPanel) {
//      setState(() {
//        isShowStickerPanel = false;
//      });
//    } else {
//      Navigator.pop(context);
//    }
//
//    return Future.value(false);
//  }

  Widget _buildListView() {
    return Expanded(
      child: Container(
        color: const Color(0xFFEDEDED),
        child: EasyRefresh(
          scrollController: _listScrollController,
          onLoad: hasMoreData
              ? () async {
                  if (messages.length > 0) {
                    _nim.loadMessages(0);
                  }
                }
              : null,
          child: ListView.builder(
            padding: EdgeInsets.all(10.0),
            reverse: true,
            controller: _listScrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildListItem(index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(int index) {
    NIMMessage message = messages[index];

    return Column(
      children: <Widget>[
        if (message.isShowTimeTag)
          Container(
            padding: EdgeInsets.only(top: 10.0, bottom: 15.0),
            child: Center(
              child: Text(
                ZKDateUtil.timestampToYMDHM(message.timestamp),
                style: TextStyle(
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
        _buildMessageItem(message),
      ],
    );
  }

  Widget _buildMessageItem(NIMMessage message) {
    if (message.isOutgoingMsg) {
      return _buildRightItem(message);
    } else {
      return _buildLeftItem(message);
    }
  }

  Widget _buildLeftItem(NIMMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: <Widget>[
          _buildAvatar(""),
          if (message.messageType == NIMMessageType.Text) _buildText(message),
          if (message.messageType == NIMMessageType.Image)
            NIMImageTile(
              imageMessage: message,
              onTap: () {
                debugPrint("图片点击事件");
              },
            ),
          if (message.messageType == NIMMessageType.Audio)
            Row(
              children: <Widget>[
                NIMAudioTile(
                  audioMessage: message,
                  currentPlayingAudioId: _currentPlayingAudioId,
                  onTap: () {
                    _playAudio(message);
                  },
                ),
                Offstage(
                  offstage: message.messageObject.isPlayed,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: new BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              ],
            ),
          if (message.messageType == NIMMessageType.Video)
            NIMVideoTile(
              videoMessage: message,
              onTap: () {
                _playVideo(message.messageObject);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRightItem(NIMMessage message) {
    bool hideErrorButton =
        (message.deliveryState == NIMMessageDeliveryState.Delivered) ||
            (message.deliveryState == NIMMessageDeliveryState.Delivering);
    bool hideProgressIndicator =
        (message.deliveryState == NIMMessageDeliveryState.Delivered) ||
            (message.deliveryState == NIMMessageDeliveryState.Failed);

    return Container(
      margin: EdgeInsets.only(bottom: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Offstage(
            offstage: hideErrorButton,
            child: GestureDetector(
              onTap: () {
                _nim.resendMessage(message.messageId);
              },
              child: Image.asset(
                "images/im_message_cell_error.png",
                width: 25.0,
                height: 25.0,
              ),
            ),
          ),
          Offstage(
            offstage: hideProgressIndicator,
            child: Container(
              child: CircularProgressIndicator(
                strokeWidth: 1.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xfff5a623),
                ),
              ),
              width: 35.0,
              height: 35.0,
              padding: EdgeInsets.all(10.0),
            ),
          ),
          if (message.messageType == NIMMessageType.Text) _buildText(message),
          if (message.messageType == NIMMessageType.Image)
            NIMImageTile(
              imageMessage: message,
              onTap: () {
                debugPrint("图片点击事件");
              },
            ),
          if (message.messageType == NIMMessageType.Audio)
            NIMAudioTile(
              audioMessage: message,
              currentPlayingAudioId: _currentPlayingAudioId,
              onTap: () {
                _playAudio(message);
              },
            ),
          if (message.messageType == NIMMessageType.Video)
            NIMVideoTile(
              videoMessage: message,
              onTap: () {
                _playVideo(message.messageObject);
              },
            ),
          _buildAvatar(""),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    return ZKCircleAvatar(
      avatarUrl: avatarUrl,
      size: 35.0,
      defaultAvatar: "images/default_user_avatar.png",
    );
  }

  Widget _buildText(NIMMessage message) {
    return Container(
      margin: EdgeInsets.only(left: 10.0, right: 10.0),
      padding: EdgeInsets.fromLTRB(15.0, 8.0, 15.0, 8.0),
      constraints: BoxConstraints(
        maxWidth: 240.0,
      ),
      decoration: BoxDecoration(
        color: message.isOutgoingMsg ? rightBubbleColor : leftBubbleColor,
        borderRadius: BorderRadius.circular(5.0),
        gradient: message.isOutgoingMsg ? rightBubbleGradient : null,
      ),
      child: Text(
        message.text ?? "",
        style: TextStyle(
          color: Colors.black,
          fontSize: 15.0,
        ),
      ),
    );
  }

  Widget _buildStickerPanel() {
    return Container(
      height: 180.0,
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xffE8E8E8),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () {},
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE8E8E8),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          InputBarButton(
            icon: _chatProvider.isShowAudioRecorder
                ? Icon(Icons.keyboard)
                : Icon(Icons.mic),
            color: const Color(0xff203152),
            onPressed: () {
              if (_chatProvider.isShowAudioRecorder) {
                FocusScope.of(context).requestFocus(_focusNode);
              } else {
                _showAudioRecorder();
              }
            },
          ),

          // Edit text
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _chatProvider.isShowAudioRecorder ? 35.0 : 80.0,
                minHeight: 35.0,
              ),
              decoration: BoxDecoration(
                color: _chatProvider.isRecording
                    ? ZKColors.place_holder
                    : Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
              child: IndexedStack(
                index: _chatProvider.isShowAudioRecorder ? 0 : 1,
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: double.infinity,
                      height: 35.0,
                      alignment: Alignment.center,
                      child: Text("按住 说话"),
                    ),
                    onTapDown: (_) {
                      if (!_chatProvider.isQuickTap) {
                        if (!_chatProvider.isRecording) {
                          _chatProvider.isRecording = true;
                          _nim.onStartRecording();
                        }
                      }
                    },
                    onTapUp: (_) {
                      // 重置快速点击标记
                      _chatProvider.isQuickTap = false;
                    },
                    onVerticalDragUpdate: (offset) {
                      // 判断是否滑出控件范围
                      if (offset.localPosition.dy < 0) {
                        // 判断一下避免无谓的刷新
                        if (!_chatProvider.willCancelRecording) {
                          // 手指滑出控件
                          _chatProvider.willCancelRecording = true;
                        }
                      } else {
                        // 判断一下避免无谓的刷新
                        if (_chatProvider.willCancelRecording) {
                          // 手指在控件内
                          _chatProvider.willCancelRecording = false;
                        }
                      }
                    },
                    onVerticalDragEnd: (offset) {
                      // 松开时如果移动位置了执行此回调
                      if (_chatProvider.willCancelRecording) {
                        // 控件外松开手指取消发送
                        _nim.onCancelRecording();
                      } else {
                        // 控件内松开手指，发送
                        _nim.onStopRecording();
                      }

                      // 重置快速点击标记
                      _chatProvider.isQuickTap = false;
                      // 停止录音
                      _chatProvider.isRecording = false;
                      _chatProvider.willCancelRecording = false;
                    },
                    onVerticalDragCancel: () {
                      // 松开时如果没移动位置执行此回调

                      // 快速点击时会优先执行此回调，此时做一个标记
                      _chatProvider.isQuickTap = true;

                      // 如果正在录音
                      if (_chatProvider.isRecording) {
                        _nim.onStopRecording();

                        // 停止录音
                        _chatProvider.isRecording = false;
                        _chatProvider.willCancelRecording = false;
                      }
                    },
                  ),
                  TextField(
                    controller: _textEditingController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    style: TextStyle(
                      color: const Color(0xff203152),
                      fontSize: 15.0,
                    ),
                    decoration: InputDecoration(
                      hintText: "",
                      hintStyle: TextStyle(color: ZKColors.place_holder),
                      border: InputBorder.none,
                      counter: null,
                      contentPadding: const EdgeInsets.all(5.0),
                    ),
                    onChanged: (text) {
                      if (text.isNotEmpty) {
                        _chatProvider.isShowSendButton = true;
                      } else {
                        _chatProvider.isShowSendButton = false;
                      }
                    },
                    onSubmitted: (text) {
                      _onSendTextMessage(text);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 暂时隐藏表情按钮
          Offstage(
            offstage: true,
            child: InputBarButton(
              icon: _chatProvider.isShowStickerPanel
                  ? Icon(Icons.keyboard)
                  : Icon(Icons.face),
              color: const Color(0xff203152),
              onPressed: () {
                if (_chatProvider.isShowStickerPanel) {
                  FocusScope.of(context).requestFocus(_focusNode);
                } else {
                  _showStickerPanel();
                }
              },
            ),
          ),

          InputBarButton(
            icon: Icon(Icons.add_circle_outline),
            color: const Color(0xff203152),
            onPressed: () {
              if (_chatProvider.isShowActionPanel) {
                FocusScope.of(context).requestFocus(_focusNode);
              } else {
                _showActionPanel();
              }
            },
          ),

          GestureDetector(
            onTap: () {
              var text = _textEditingController.text;
              _onSendTextMessage(text);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.linear,
              width: _chatProvider.isShowSendButton ? 50.0 : 0,
              height: 30.0,
              margin: EdgeInsets.only(
                  right: _chatProvider.isShowSendButton ? 10.0 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF6AB00),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Center(
                child: AnimatedOpacity(
                  duration: Duration(
                      milliseconds: _chatProvider.isShowSendButton ? 200 : 100),
                  opacity: _chatProvider.isShowSendButton ? 1.0 : 0.0,
                  child: Text(
                    "发送",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      height: 180.0,
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xffE8E8E8),
            width: 0.5,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IMActionPanelItem(
            icon: Image.asset(
              "images/im_action_panel_gallery.png",
              width: 75.0,
              height: 75.0,
            ),
            title: "相册",
            onTap: () {
              _getFileFromGallery();
            },
          ),
          IMActionPanelItem(
            icon: Image.asset(
              "images/im_action_panel_camera.png",
              width: 75.0,
              height: 75.0,
            ),
            title: "拍摄",
            onTap: () {
              _getFileFromCamera();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingDialog() {
    return Container(
      width: 160.0,
      height: 130.0,
      decoration: BoxDecoration(
        color: Color.fromARGB(220, 0, 0, 0),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            _chatProvider.willCancelRecording ? Icons.undo : Icons.mic,
            color: ZKColors.text_light,
            size: 40.0,
          ),
          SizedBox(
            height: 16.0,
          ),
          Container(
            padding: EdgeInsets.all(3),
            decoration: _chatProvider.willCancelRecording
                ? BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5.0),
                  )
                : null,
            child: Text(
              _chatProvider.willCancelRecording ? "松开手指，取消发送" : "手指上滑，取消发送",
              style: TextStyle(
                color: _chatProvider.willCancelRecording
                    ? Colors.white
                    : ZKColors.text_light,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _getImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      _nim.sendImage(imageFile.path);
    }
  }

  Future _getFileFromGallery() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
              bottom: ZKCommonUtils.getBottomBarHeight(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Center(
                  child: Text("图片"),
                ),
                onTap: () async {
                  File imageFile =
                      await ImagePicker.pickImage(source: ImageSource.gallery);

                  sendImage(imageFile);

                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Center(
                  child: Text("视频"),
                ),
                onTap: () async {
                  File videoFile =
                      await ImagePicker.pickVideo(source: ImageSource.gallery);

                  sendVideo(videoFile);

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future _getFileFromCamera() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
              bottom: ZKCommonUtils.getBottomBarHeight(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Center(
                  child: const Text("拍照"),
                ),
                onTap: () async {
                  File imageFile =
                      await ImagePicker.pickImage(source: ImageSource.camera);

                  sendImage(imageFile);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Center(
                  child: const Text("录像"),
                ),
                onTap: () async {
                  File videoFile =
                      await ImagePicker.pickVideo(source: ImageSource.camera);

                  sendVideo(videoFile);

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future _takePhoto() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);

    sendImage(imageFile);
  }

  Future _takeVideo() async {
    File videoFile = await ImagePicker.pickVideo(source: ImageSource.camera);

    sendVideo(videoFile);
  }

  void sendImage(File file) {
    if (file != null) {
      _nim.sendImage(file.path);
    }
  }

  void sendVideo(File file) {
    if (file != null) {
      _nim.sendVideo(file.path);
    }
  }

  void _showAudioRecorder() async {
    if (Platform.isAndroid) {
      // 检查数据存储权限
      PermissionStatus storagePermissionStatus = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      // print(storagePermissionStatus);

      if (storagePermissionStatus != PermissionStatus.granted) {
        // 申请权限
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);

        // print(permissions[PermissionGroup.storage]);

        storagePermissionStatus = permissions[PermissionGroup.storage];
      }

      // 检查麦克风权限
      PermissionStatus microphonePermissionStatus = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.microphone);
      // print(microphonePermissionStatus);

      if (microphonePermissionStatus != PermissionStatus.granted) {
        // 申请权限
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler().requestPermissions(
                [PermissionGroup.storage, PermissionGroup.microphone]);

        // print(permissions[PermissionGroup.microphone]);

        microphonePermissionStatus = permissions[PermissionGroup.microphone];
      }

      if (microphonePermissionStatus == PermissionStatus.granted &&
          storagePermissionStatus == PermissionStatus.granted) {
        _chatProvider.willShowAudioRecorder();

        if (_chatProvider.isEditing) {
          // 隐藏软键盘
          _focusNode.unfocus();
        } else {
          _chatProvider.showAudioRecorder();
        }
      } else {
        ZKCommonUtils.showToast("您尚未授予本应用数据存储或麦克风权限,请在系统设置中打开。");
      }
    } else {
      // 检查麦克风权限
      PermissionStatus microphonePermissionStatus = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.microphone);
      // print(microphonePermissionStatus);

      if (microphonePermissionStatus != PermissionStatus.granted) {
        // 申请权限
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler().requestPermissions(
                [PermissionGroup.storage, PermissionGroup.microphone]);

        // print(permissions[PermissionGroup.microphone]);

        microphonePermissionStatus = permissions[PermissionGroup.microphone];
      }

      if (microphonePermissionStatus == PermissionStatus.granted) {
        _chatProvider.willShowAudioRecorder();

        if (_chatProvider.isEditing) {
          // 隐藏软键盘
          _focusNode.unfocus();
        } else {
          _chatProvider.showAudioRecorder();
        }
      } else {
        ZKCommonUtils.showToast("您尚未授予本应用麦克风权限,请在系统设置中打开。");
      }
    }
  }

  void _showStickerPanel() {
    // 隐藏软键盘
    _focusNode.unfocus();

    _chatProvider.showStickerPanel();
  }

  void _showActionPanel() {
    // 需要等键盘动画完成后再显示
    _chatProvider.willShowActionPanel();

    if (_chatProvider.isEditing) {
      // 隐藏软键盘
      _focusNode.unfocus();
    } else {
      _chatProvider.showActionPanel();
    }
  }

  void _playAudio(NIMMessage audioMessage) async {
    var audioObject = audioMessage.messageObject;

    if (!audioObject.isPlayed) {
      // 标记已读
      audioObject.isPlayed = true;
      _nim.markAudioMessageRead(audioMessage.messageId);
    }

    bool isLocal = false;

    String audioPath = "";

    // 先检查是否已经保存到本地
    if (audioObject.path.isNotEmpty) {
      audioPath = audioObject.path;
      isLocal = true;
    } else {
      audioPath = audioObject.url;
      isLocal = false;
    }

    if (audioPath.isEmpty) {
      return;
    }

    debugPrint("播放语音\n" + audioPath);

    if (_currentPlayingAudioId.isEmpty) {
      // 如果当前没有播放

      // 播放语音
      int result = await _audioPlayer.play(audioPath, isLocal: isLocal);
      if (result == 1) {
        _currentPlayingAudioId = audioMessage.messageId;
      }
    } else {
      // 如果当前在播放
      if (audioMessage.messageId == _currentPlayingAudioId) {
        // 如果点击的是当前播放的
        // 停止播放
        await _audioPlayer.stop();
      } else {
        // 如果点击的不是当前播放的
        // 播放新的
        int result = await _audioPlayer.play(audioPath, isLocal: isLocal);
        if (result == 1) {
          _currentPlayingAudioId = audioMessage.messageId;
        }
      }
    }
  }

  void _playVideo(NIMMessageObject videoObject) {
    debugPrint("播放视频");
    debugPrint(videoObject.url);
    debugPrint(videoObject.path);
  }

  void _onSendTextMessage(String content) {
    FocusScope.of(context).requestFocus(_focusNode);

    if (content == null || content.isEmpty) {
      return;
    }

    _textEditingController.clear();

    _chatProvider.isShowSendButton = false;

    _nim.sendText(content);

    _listScrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

//      _listScrollController.animateTo(
//        listScrollController.position.maxScrollExtent,
//        duration: Duration(milliseconds: 300),
//        curve: Curves.easeOut,
//      );
  }

  @override
  void dispose() {
//    _refreshController.dispose();
    _listScrollController.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();

    _audioPlayer.stop();

//    ChannelUtils.instance.imExitChat();
    _nim.exitChat();

    super.dispose();
  }
}

class NIMImageTile extends StatelessWidget {
  final NIMMessage imageMessage;
  final Function onTap;

  NIMImageTile({
    Key key,
    @required this.imageMessage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var imageObject = imageMessage.messageObject;

    double width = 105.0;
    double height = 105.0;

    if (imageObject.width > imageObject.height) {
      width = 140.0;
      height = 105.0;
    } else if (imageObject.width < imageObject.height) {
      width = 105.0;
      height = 140.0;
    }

    String errorImagePath = "images/img_not_available.png";
    if ((imageObject?.thumbPath ?? "").isNotEmpty) {
      errorImagePath = imageObject.thumbPath;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: 10.0, right: 10.0),
        child: ZKNetworkImage(
          imageUrl: imageObject?.thumbUrl,
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(5.0),
          errorImagePath: errorImagePath,
        ),
      ),
    );
  }
}

class NIMVideoTile extends StatelessWidget {
  final NIMMessage videoMessage;
  final Function onTap;

  NIMVideoTile({
    Key key,
    @required this.videoMessage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var videoObject = videoMessage.messageObject;

    double width = 105.0;
    double height = 105.0;

    if (videoObject.width > videoObject.height) {
      width = 140.0;
      height = 105.0;
    } else if (videoObject.width < videoObject.height) {
      width = 105.0;
      height = 140.0;
    }

//    String errorImagePath = "images/img_not_available.png";
//    if ((imageObject?.thumbPath ?? "").isNotEmpty) {
//      errorImagePath = imageObject.thumbPath;
//    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(left: 10.0, right: 10.0),
        child: Stack(
          children: <Widget>[
            ZKNetworkImage(
              imageUrl: videoObject?.coverUrl,
              width: width,
              height: height,
              borderRadius: BorderRadius.circular(5.0),
              errorImagePath: "images/img_not_available.png",
            ),
            Align(
              alignment: AlignmentDirectional.center,
              child: Image.asset(
                'images/im_video_play.png',
                width: 35.0,
                height: 35.0,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Text(
                  videoObject.videoDurationDesc,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NIMAudioTile extends StatelessWidget {
  final NIMMessage audioMessage;
  final String currentPlayingAudioId;
  final Function onTap;

  NIMAudioTile({
    Key key,
    @required this.audioMessage,
    this.currentPlayingAudioId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imagePath;

    if (audioMessage.isOutgoingMsg) {
      if (audioMessage.messageId == currentPlayingAudioId) {
        imagePath = "images/im_audio_play_right.gif";
      } else {
        imagePath = "images/im_audio_stop_right.png";
      }
    } else {
      if (audioMessage.messageId == currentPlayingAudioId) {
        imagePath = "images/im_audio_play_left.gif";
      } else {
        imagePath = "images/im_audio_stop_left.png";
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
        padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        decoration: BoxDecoration(
          color:
              audioMessage.isOutgoingMsg ? rightBubbleColor : leftBubbleColor,
          borderRadius: BorderRadius.circular(8.0),
          gradient: audioMessage.isOutgoingMsg ? rightBubbleGradient : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              imagePath,
              width: 20.0,
              height: 20.0,
            ),
            SizedBox(
              width: 8.0,
            ),
            Text(
              audioMessage.messageObject.audioDurationDesc,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13.0,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class IMActionPanelItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final Function onTap;

  IMActionPanelItem({
    Key key,
    @required this.icon,
    @required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF75747D),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InputBarButton extends StatelessWidget {
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final Widget icon;
  final Color color;
  final VoidCallback onPressed;

  const InputBarButton({
    Key key,
    this.iconSize = 24.0,
    this.padding =
        const EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
    @required this.icon,
    this.color,
    @required this.onPressed,
  })  : assert(iconSize != null),
        assert(padding != null),
        assert(icon != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: padding,
        child: IconTheme.merge(
          data: IconThemeData(
            size: iconSize,
            color: color,
          ),
          child: icon,
        ),
      ),
    );
  }
}
