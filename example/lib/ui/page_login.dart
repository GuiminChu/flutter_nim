import 'package:flutter/material.dart';
import 'package:flutter_nim/flutter_nim.dart';
import 'package:flutter_nim_example/utils/user_utils.dart';
import 'package:flutter_nim_example/zeus_kit/zeus_kit.dart';
import 'package:flutter_nim_example/ui/page_recent_sessions.dart';

class LoginHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

/// 登录页面
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _accountEditingController = TextEditingController();
  TextEditingController _passwordEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("登录"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _accountEditingController,
              decoration: InputDecoration(hintText: "请输入账号"),
            ),
            TextField(
              controller: _passwordEditingController,
              decoration: InputDecoration(hintText: "请输入密码"),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "请使用您在云信Demo中注册的账号密码",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            RaisedButton(
              child: Text("登录"),
              onPressed: () {
                _login();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
    final imAccount = _accountEditingController.text;
    final imToken = ZKCommonUtils.generateMd5(_passwordEditingController.text);

    bool isLoginSuccess = await FlutterNIM().login(imAccount, imToken);

    if (isLoginSuccess) {
      UserUtils.saveIMLoginInfo(imAccount, imToken);
      ZKRouter.pushWidget(context, MyApp());
    } else {
      ZKCommonUtils.showToast("登录失败，请检查您的账号密码");
    }
  }
}
