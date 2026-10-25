import 'dart:io';

class AutoStartManager {
  static const String _keyName = 'Vellor Client';
  static const String _regPath = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  static Future<bool> isEnabled() async {
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('reg', ['query', _regPath, '/v', _keyName]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setEnabled(bool enable) async {
    if (!Platform.isWindows) return false;
    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        await Process.run('reg', [
          'add',
          _regPath,
          '/v',
          _keyName,
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath" --minimized',
          '/f',
        ]);
      } else {
        await Process.run('reg', [
          'delete',
          _regPath,
          '/v',
          _keyName,
          '/f',
        ]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
