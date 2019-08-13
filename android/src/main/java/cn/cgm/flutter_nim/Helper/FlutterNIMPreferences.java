package cn.cgm.flutter_nim.Helper;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;

import com.netease.nimlib.sdk.auth.LoginInfo;

public class FlutterNIMPreferences {
    private static final String KEY_USER_ACCOUNT = "flutter_nim_account";
    private static final String KEY_USER_TOKEN = "flutter_nim_token";

    private static Context context;

    private static Context getContext() {
        return context;
    }

    public static void setContext(Context context) {
        FlutterNIMPreferences.context = context.getApplicationContext();
    }

    /**
     * 获取云信用户登录信息，用于自动登录
     */
    public static LoginInfo getLoginInfo() {
        String account = getUserAccount();
        String token = getUserToken();

        if (!TextUtils.isEmpty(account) && !TextUtils.isEmpty(token)) {
            return new LoginInfo(account, token);
        } else {
            return null;
        }
    }

    static void saveUserAccount(String account) {
        saveString(KEY_USER_ACCOUNT, account);
    }

    private static String getUserAccount() {
        return getString(KEY_USER_ACCOUNT);
    }

    static void saveUserToken(String token) {
        saveString(KEY_USER_TOKEN, token);
    }

    private static String getUserToken() {
        return getString(KEY_USER_TOKEN);
    }

    public static void saveString(String key, String value) {
        SharedPreferences.Editor editor = getSharedPreferences().edit();
        editor.putString(key, value);
        editor.apply();
    }

    public static String getString(String key) {
        return getSharedPreferences().getString(key, null);
    }

    public static void clear() {
        SharedPreferences.Editor editor = getSharedPreferences().edit();
        editor.clear();
        editor.apply();
    }

    private static SharedPreferences getSharedPreferences() {
        return getContext().getSharedPreferences("FlutterNIM", Context.MODE_PRIVATE);
    }
}
