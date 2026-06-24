import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VipService extends ChangeNotifier {
  static final VipService instance = VipService._();
  VipService._();

  bool _isVip = false;
  bool get isVip => _isVip;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isVip = prefs.getBool('is_vip') ?? false;
  }

  Future<void> upgrade() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_vip', true);
    _isVip = true;
    notifyListeners();
  }
}
