import 'package:flutter/material.dart';

import 'package:flutter_nim/flutter_nim.dart';
import 'package:flutter_nim_example/utils/user_utils.dart';
import 'package:flutter_nim_example/ui/page_login.dart';
import 'package:flutter_nim_example/ui/page_recent_sessions.dart';

void main() async {
  final imAccount = await UserUtils.imAccount;
  final imToken = await UserUtils.imToken;

  FlutterNIM().init(
    appKey: "45c6af3c98409b18a84451215d0bdd6e",
    apnsCername: "ENTERPRISE",
    apnsCernameDevelop: "DEVELOPER",
    imAccount: imAccount,
    imToken: imToken,
  );

  bool isLogin = await UserUtils.isLogin();

  if (isLogin) {
    runApp(MyApp());
  } else {
    runApp(LoginHomePage());
  }
}
