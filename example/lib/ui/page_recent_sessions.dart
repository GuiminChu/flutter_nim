import 'package:flutter/material.dart';
import 'package:flutter_nim/flutter_nim.dart';

import 'package:flutter_nim_example/provider/provider.dart';
import 'package:flutter_nim_example/ui/page_login.dart';
import 'package:flutter_nim_example/utils/user_utils.dart';
import 'package:flutter_nim_example/zeus_kit/zeus_kit.dart';
import 'package:flutter_nim_example/ui/page_chat.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NIMProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        home: RecentSessionsPage(),
      ),
    );
  }
}

/// 最近会话
class RecentSessionsPage extends StatefulWidget {
  @override
  _RecentSessionsPageState createState() => _RecentSessionsPageState();
}

class _RecentSessionsPageState extends State<RecentSessionsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("消息"),
          centerTitle: true,
          elevation: 0.5,
          actions: _buildAppBarActions(),
        ),
        body: _buildBodyWidget(),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      GestureDetector(
        onTap: () {
          FlutterNIM().logout();

          UserUtils.clearLoginInfo();

          ZKRouter.pushWidget(
            context,
            LoginHomePage(),
            replaceCurrent: true,
          );
        },
        child: Container(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          alignment: Alignment.center,
          child: Text(
            "登出",
            style: TextStyle(
              fontSize: 15.0,
            ),
          ),
        ),
      )
    ];
  }

  Widget _buildBodyWidget() {
    return Container(
      color: Colors.white,
      child: _buildListView(),
    );
  }

  Widget _buildListView() {
    return Consumer<NIMProvider>(builder: (context, provider, _) {
      return Stack(
        children: <Widget>[
          Offstage(
            offstage: provider.recentSessions.isEmpty,
            child: ListView.builder(
              itemCount: provider.recentSessions.length,
              itemBuilder: (context, index) {
                return _IMRecentSessionListItem(
                    recentSession: provider.recentSessions[index]);
              },
            ),
          ),
          Offstage(
            offstage: provider.recentSessions.isNotEmpty,
            child: Text("暂时没有会话嗷！"),
          ),
        ],
      );
    });
  }
}

class _IMRecentSessionListItem extends StatelessWidget {
  final NIMRecentSession recentSession;

  _IMRecentSessionListItem({
    Key? key,
    required this.recentSession,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        bool isSuccess =
            await FlutterNIM().startChat(recentSession.sessionId!.toLowerCase());
        if (isSuccess) {
          ZKRouter.pushWidget(
            context,
            Chat(
              sessionId: recentSession.sessionId!,
              chatName: recentSession.userInfo?.nickname ?? "",
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              width: 0.0,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            ZKCircleAvatar(
              avatarUrl: recentSession.userInfo?.avatarUrl ?? "",
              size: 36.0,
              defaultAvatar: "images/default_user_avatar.png",
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            recentSession.userInfo?.nickname ?? "无名氏",
                            style: TextStyle(
                              color: ZKColors.text_dark,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ZKDateUtil.timestampToYMDHM(recentSession.timestamp!),
                          style: TextStyle(
                            color: ZKColors.text_gray,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
                    Row(
                      children: <Widget>[
                        // 最后消息文本
                        Expanded(
                          child: Text(
                            recentSession.messageContent!,
                            style: TextStyle(
                              color: ZKColors.text_gray,
                              fontSize: 13.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 未读数
                        Offstage(
                          offstage: recentSession.unreadCount == 0,
                          child: Container(
                            child: Center(
                              child: Text(
                                "${recentSession.unreadCount}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(9.0),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18.0,
                              minHeight: 18.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
