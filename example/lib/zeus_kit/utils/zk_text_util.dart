class ZKTextUtil {
  /// isEmpty
  static bool isEmpty(String text) {
    return text == null || text.isEmpty;
  }

  /// isNotEmpty
  static bool isNotEmpty(String text) {
    return text != null && text.isNotEmpty;
  }

  /// isDouble
  static bool isDouble(String text) {
    if (isEmpty(text)) {
      return false;
    }

    if (double.tryParse(text) == null) {
      return false;
    }

    return true;
  }
}
