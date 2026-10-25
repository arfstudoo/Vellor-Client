import 'dart:io';
import 'package:flutter/services.dart';

class TrayService {
  static const MethodChannel _channel = MethodChannel('dev.vellor/tray');
  static bool _initialized = false;

  static void init({
    required VoidCallback onToggleConnect,
    required Future<void> Function() onExit,
  }) {
    if (_initialized || !Platform.isWindows) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'toggleConnect':
          onToggleConnect();
          break;
        case 'requestExit':
          await onExit();
          await _channel.invokeMethod('exitApp');
          break;
      }
    });
  }

  static Future<void> updateStatus({
    required bool connected,
    required String text,
  }) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('updateStatus', {
        'connected': connected,
        'text': text,
      });
    } catch (_) {}
  }

  static Future<void> hideToTray() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('hideToTray');
    } catch (_) {}
  }

  static Future<void> showWindow() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('showWindow');
    } catch (_) {}
  }
}
