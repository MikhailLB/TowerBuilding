import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads cold-start push URLs that SceneDelegate captured before Dart ran.
///
/// SceneDelegate.swift writes the URL to UserDefaults under key
/// `flutter.tb_gate_cold_url`. The `flutter.` prefix is required:
/// SharedPreferences on iOS uses that prefix, so reading via
/// SharedPreferences is equivalent to reading UserDefaults directly.
class NativeLinkBridge {
  static const String _key = 'tb_gate_cold_url';

  /// Returns and atomically clears the URL stored by SceneDelegate.
  /// Returns null on non-iOS or when no URL is stored.
  static Future<String?> consumeColdUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        debugPrint('[TB.NATIVE] consumeColdUrl -> null');
        return null;
      }
      await prefs.remove(_key);
      debugPrint('[TB.NATIVE] consumeColdUrl -> "$raw"');
      return raw.trim();
    } catch (err) {
      debugPrint('[TB.NATIVE] consumeColdUrl failed: $err');
      return null;
    }
  }
}
