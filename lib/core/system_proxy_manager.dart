import 'dart:io';

class SystemProxyManager {
  static const int defaultPort = 20808;
  static const String defaultHost = '127.0.0.1';

  static Future<bool> enableProxy({
    String host = defaultHost,
    int port = defaultPort,
  }) async {
    if (!Platform.isWindows) return true;
    try {
      final proxyServer = '$host:$port';
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);
      await _refreshWinINet();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> disableProxy() async {
    if (!Platform.isWindows) return true;
    try {
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);
      await _refreshWinINet();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _refreshWinINet() async {
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WinINet {
            [DllImport("wininet.dll", SetLastError = true)]
            public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
        }
"@;
        [WinINet]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0);
        [WinINet]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0);
        '''
      ]);
    } catch (_) {}
  }
}
