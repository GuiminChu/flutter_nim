class NIMUser {
  String nickname;
  String avatarUrl;
  String userExt;

  NIMUser({
    this.nickname,
    this.avatarUrl,
    this.userExt,
  });

  NIMUser.fromJson(Map<String, dynamic> json) {
    avatarUrl = json['avatarUrl'];
    userExt = json['userExt'];
    nickname = json['nickname'];
  }
}
