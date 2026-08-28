import 'package:flutter/foundation.dart';

class ErpServices {
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('ErpServices initialized locally.');
    }
  }
}
