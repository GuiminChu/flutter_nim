class ZKDateUtil {
  /// 毫秒时间戳 -> yyyy-MM-dd HH:mm
  static String timestampToYMDHM(int timestamp) {
    if (timestamp == null) {
      return "";
    }
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateString = date.toString();
    dateString = dateString.substring(0, "yyyy-MM-dd HH:mm".length);
    return dateString;
  }

  /// 毫秒时间戳 -> yyyy-MM
  static String timestampToYM(int timestamp) {
    if (timestamp == null) {
      return "";
    }
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateString = date.toString();
    dateString = dateString.substring(0, "yyyy-MM".length);
    return dateString;
  }

  /// 毫秒时间戳 -> HH:mm
  static String timestampToHM(int timestamp) {
    if (timestamp == null) {
      return "";
    }
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateString = date.toString();
    dateString = dateString.substring(11, 16);
    return dateString;
  }
}
