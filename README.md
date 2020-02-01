# flutter_nim
用于`Flutter`的网易云信SDK
    
    
## 目前功能
    
* 登录
* 自动登录
* 退出登录
* 踢出
* 获取最近会话列表
* 删除一个最近会话列表
* 开启新会话
* 关闭打开的会话
* 获取会话消息
* 发送接收文本、图片、视频、音频消息
* 发送接收自定义消息
* 标记音频已读
* 调用`NIMSDK`能力实现语音消息的录制、发送
 
      
> ##### 不支持群组聊天      
      

## Screenshot

![Screenshot1](https://github.com/GuiminChu/flutter_nim/blob/develop/screenshot/Screen%20Shot%201.png)

## 部分示例

### 初始化

使用前，先进行初始化：
      
```dart 
void main() async {
  FlutterNIM().init(
    appKey: "123456",
    apnsCername: "ABCDEFG", // iOS 生产环境证书名称
    apnsCernameDevelop: "ABCDEFG", // iOS 测试环境证书名称
    imAccount: "123456",
    imToken: "123456",
  );

  runApp(MyApp());
}
```

由于 SDK 限制，Android 平台依然需要去 Application 中初始化，可以参照以下代码：

```java
public class MyApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();

        FlutterNIMPreferences.setContext(this);
        // SDK初始化（启动后台服务，若已经存在用户登录信息， SDK 将完成自动登录）
        NIMClient.init(this, FlutterNIMPreferences.getLoginInfo(), buildSDKOptions());
    }

    // 网易云信配置（此处也可以使用自己的配置）
    private SDKOptions buildSDKOptions() {
        return FlutterNIMSDKOptionConfig.getSDKOptions(this, "123456", buildMixPushConfig());
    }

    // 网易云信第三方推送配置
    private MixPushConfig buildMixPushConfig() {

        MixPushConfig config = new MixPushConfig();

        // 小米推送
        config.xmAppId = "123456";
        config.xmAppKey = "123456";
        config.xmCertificateName = "ABCDEFG";

        // 华为推送
        config.hwCertificateName = "ABCDEFG";
        ...
        
        return config;
    }
}

```

### 登录

```dart
bool isSuccess = await FlutterNIM().login(imAccount, imToken);
```

### 退出登录

```dart
FlutterNIM().logout();
```

### 踢出

```dart
FlutterNIM().kickReasonResponse.listen((NIMKickReason reason) {
    // 处理被踢下线逻辑
});
```

### 最近会话列表

手动获取最近会话列表：

```dart
FlutterNIM().loadRecentSessions();
```

监听最近会话，手动调用获取最近会话列表或最近会话列表有变更（新增、更新、删除、标记已读）都会触发此回调。

```dart
FlutterNIM().recentSessionsResponse.listen((recentSessions) {
    List<NIMSession> _recentSessions = recentSessions;

    // 在此可计算最近会话总未读数
    int unreadNum = recentSessions
        .map((s) => s.unreadCount)
        .fold(0, (curr, next) => curr + next);
    });
```

删除某项会话（只删除本地缓存，不会删除云端记录）

```dart
FlutterNIM().deleteRecentSession(session.sessionId);
```

### 会话

开启一个新会话

```dart
bool isSuccess = await FlutterNIM().startChat(session.sessionId);
```

监听会话消息

```dart
FlutterNIM().messagesResponse.listen((messages) {
    List<NIMMessage> _messages = messages;

    // 求余，如果结果等于零则可能还有更多数据
    int _remainder = this._messages.length % 20;
    bool _hasMoreData = remainder == 0;
    });
```

退出聊天页面时，需要将会话关闭

```dart
FlutterNIM().exitChat();
```

发送消息

```dart
// 发送文本消息
FlutterNIM().sendText(content);

// 发送图片消息
FlutterNIM().sendImage(file.path);

// 发送视频消息
FlutterNIM().sendVideo(file.path);
```

语音消息调用了原生云信SDK的录音能力

```dart
// 开始录音
FlutterNIM().onStartRecording();

// 结束录音，结束后自动发送语音消息
FlutterNIM().onStopRecording();

// 取消录音，不会发送
FlutterNIM().onCancelRecording();
```

### 自定义消息

把自定义消息内容放在`Map`中：

```dart

    // 随便自己定义
    Map<String, dynamic> customObject = {
      "type": "自定义",
      "url": "xxx",
      ...
    };

    FlutterNIM().sendCustomMessage(
      customObject,
      apnsContent: "[发来了一条自定义消息]",
    );
    
```

接收到的自定义消息体以`JSON`字符串的格式存在`NIMMessage`的`customMessageContent`中，然后自己去解析：

```dart
final customObjectMap = json.decode(customMessageContent);
// 自定义
var model = CustomModel.fromJson(customObjectMap);
```


