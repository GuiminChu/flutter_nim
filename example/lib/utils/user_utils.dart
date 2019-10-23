import 'package:shared_preferences/shared_preferences.dart';

class UserUtils {
  static const _imAccountKey = "imAccount";
  static const _imTokenKey = "imToken";

  static void saveIMLoginInfo(String imAccount, String imToken) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString(_imAccountKey, imAccount);
    preferences.setString(_imTokenKey, imToken);
  }

  static Future<String> get imAccount async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_imAccountKey);
  }

  static Future<String> get imToken async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_imTokenKey);
  }

  /// 是否登录
  static Future<bool> isLogin() async {
    var accessToken = await imToken;
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }
    return true;
  }

  /// 清空, 登出时使用
  static void clearLoginInfo() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    preferences.remove(_imAccountKey);
    preferences.remove(_imTokenKey);
  }
}
