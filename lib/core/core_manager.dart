import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_singbox_client/flutter_singbox_client.dart' as sb;
import '../models/profile.dart';
import '../models/traffic_stats.dart';
import 'config_generator.dart';
import 'storage.dart';
import 'system_proxy_manager.dart';

enum CoreState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class CoreManager {
  static final CoreManager instance = CoreManager._internal();
  CoreManager._internal();

  Process? _process;
  Timer? _trafficTimer;
  HttpClient? _apiClient;

  sb.SingboxClient? _mobileClient;
  StreamSubscription? _mobileStateSub;
  StreamSubscription? _mobileStatsSub;
  StreamSubscription? _mobileFaultSub;

  CoreState _state = CoreState.disconnected;
  String _lastError = '';
  TrafficStats _stats = const TrafficStats();

  final _stateController = StreamController<CoreState>.broadcast();
  final _statsController = StreamController<TrafficStats>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Stream<CoreState> get stateStream => _stateController.stream;
  Stream<TrafficStats> get statsStream => _statsController.stream;
  Stream<String> get logStream => _logController.stream;

  CoreState get state => _state;
  String get lastError => _lastError;
  TrafficStats get stats => _stats;

  String _cleanAnsi(String text) {
    return text.replaceAll(RegExp(r'\x1B\[[0-9;]*[mK]'), '').trim();
  }

  String? _resolveCorePath() {
    final candidates = [
      '${Directory.current.path}\\core\\sing-box.exe',
      '${AppStorage.getStorageDirectory().path}\\sing-box.exe',
      '${File(Platform.resolvedExecutable).parent.path}\\core\\sing-box.exe',
      '${File(Platform.resolvedExecutable).parent.path}\\sing-box.exe',
    ];

    for (final path in candidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  String _mode = 'tun';
  String get mode => _mode;

  Future<bool> start({
    required Profile profile,
    required bool bypassRu,
    String mode = 'tun',
    List<String> splitTunnelingApps = const [],
    bool tlsFragment = false,
    bool killSwitch = false,
  }) async {
    _mode = mode;
    if (_state == CoreState.connected || _state == CoreState.connecting) {
      await stop();
    }

    _setState(CoreState.connecting);
    _lastError = '';

    if (Platform.isAndroid) {
      try {
        _mobileClient ??= sb.SingboxClient();
        await _mobileClient!.initialize();
        final hasPerm = await _mobileClient!.requestVPNPermission();
        if (!hasPerm) {
          _lastError = 'Требуется системное разрешение на VPN';
          _setState(CoreState.disconnected);
          return false;
        }

        final bool enableTun = mode == 'tun';
        final configJson = ConfigGenerator.generateSingBoxConfig(
          profile: profile,
          bypassRu: bypassRu,
          enableTun: enableTun,
          splitTunnelingApps: splitTunnelingApps,
          mixedPort: SystemProxyManager.defaultPort,
          tlsFragment: tlsFragment,
          killSwitch: killSwitch,
        );

        _mobileStateSub?.cancel();
        _mobileStateSub = _mobileClient!.serviceStateStream.listen((sState) {
          if (sState == sb.ServiceState.started) {
            _setState(CoreState.connected);
          } else if (sState == sb.ServiceState.stopped) {
            _setState(CoreState.disconnected);
          } else if (sState == sb.ServiceState.starting) {
            _setState(CoreState.connecting);
          } else if (sState == sb.ServiceState.stopping) {
            _setState(CoreState.disconnecting);
          }
        });

        _mobileStatsSub?.cancel();
        _mobileStatsSub = _mobileClient!.trafficStatsStream.listen((s) {
          _stats = _stats.copyWith(
            uploadBytesPerSec: (s.uplinkBps / 8).round(),
            downloadBytesPerSec: (s.downlinkBps / 8).round(),
            totalUploadBytes: s.uplinkTotalBytes,
            totalDownloadBytes: s.downlinkTotalBytes,
          );
          _statsController.add(_stats);
        });

        _mobileFaultSub?.cancel();
        _mobileFaultSub = _mobileClient!.faultStream.listen((fault) {
          _lastError = fault;
          _setState(CoreState.error);
        });

        await _mobileClient!.connect(sb.SessionOptions(
          config: configJson,
          networkMode: enableTun ? sb.NetworkMode.vpn : sb.NetworkMode.proxy,
          notification: const sb.NotificationConfig(
            title: 'Vellor Client',
            showTrafficStats: true,
            showStopButton: true,
            stopButtonLabel: 'Отключить',
          ),
        ));

        _setState(CoreState.connected);
        return true;
      } catch (e) {
        _lastError = e.toString();
        _setState(CoreState.error);
        return false;
      }
    }

    final exePath = _resolveCorePath();
    if (exePath == null) {
      _lastError = 'Сетевой модуль sing-box не найден в каталоге приложения';
      _setState(CoreState.error);
      return false;
    }

    try {
      final bool enableTun = mode == 'tun';
      final configJson = ConfigGenerator.generateSingBoxConfig(
        profile: profile,
        bypassRu: bypassRu,
        enableTun: enableTun,
        splitTunnelingApps: splitTunnelingApps,
        mixedPort: SystemProxyManager.defaultPort,
        tlsFragment: tlsFragment,
        killSwitch: killSwitch,
      );

      final storageDir = AppStorage.getStorageDirectory();
      final configFile = File('${storageDir.path}\\active_config.json');
      await configFile.writeAsString(configJson);

      final exeDir = File(exePath).parent.path;

      _process = await Process.start(
        exePath,
        ['run', '-c', configFile.path],
        workingDirectory: exeDir,
        mode: ProcessStartMode.normal,
      );

      _process!.stdout.transform(utf8.decoder).listen((data) {
        _logController.add(data);
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        _logController.add(data);
        final clean = _cleanAnsi(data);
        if (clean.toLowerCase().contains('access is denied')) {
          _lastError = 'Запустите приложение от имени администратора для режима TUN';
        } else if (clean.toLowerCase().contains('fatal') ||
            clean.toLowerCase().contains('panic')) {
          if (_lastError.isEmpty) {
            _lastError = clean;
          }
        }
      });

      _process!.exitCode.then((code) {
        _stopTrafficMonitor();
        if (!killSwitch) {
          SystemProxyManager.disableProxy();
        }
        if (_state == CoreState.connected || _state == CoreState.connecting) {
          if (code != 0 && _lastError.isEmpty) {
            _lastError = killSwitch
                ? 'Kill Switch активен: соединение разорвано, трафик заблокирован'
                : 'Процесс завершился с кодом $code';
          }
          _setState(code == 0 ? CoreState.disconnected : CoreState.error);
        }
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      if (_process == null || _state == CoreState.error) {
        if (!enableTun) {
          await SystemProxyManager.disableProxy();
        }
        return false;
      }

      if (!enableTun) {
        await SystemProxyManager.enableProxy(port: SystemProxyManager.defaultPort);
      } else {
        await SystemProxyManager.disableProxy();
      }

      _setState(CoreState.connected);
      _startTrafficMonitor();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _setState(CoreState.error);
      return false;
    }
  }

  Future<void> stop() async {
    _setState(CoreState.disconnecting);

    if (Platform.isAndroid) {
      try {
        await _mobileClient?.disconnect();
      } catch (_) {}
      _mobileStateSub?.cancel();
      _mobileStatsSub?.cancel();
      _mobileFaultSub?.cancel();
      _stats = const TrafficStats();
      _statsController.add(_stats);
      _setState(CoreState.disconnected);
      return;
    }

    _stopTrafficMonitor();
    await SystemProxyManager.disableProxy();

    if (_process != null) {
      try {
        _process!.kill();
        await _process!.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            Process.runSync('taskkill', ['/F', '/T', '/PID', '${_process!.pid}']);
            return -1;
          },
        );
      } catch (_) {}
      _process = null;
    }

    _stats = const TrafficStats();
    _statsController.add(_stats);
    _setState(CoreState.disconnected);
  }

  void _setState(CoreState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _startTrafficMonitor() {
    _stopTrafficMonitor();
    _apiClient = HttpClient();
    _apiClient!.connectionTimeout = const Duration(seconds: 1);

    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_state != CoreState.connected) {
        timer.cancel();
        return;
      }

      try {
        final request = await _apiClient!.getUrl(
          Uri.parse('http://127.0.0.1:9090/traffic'),
        );
        final response = await request.close().timeout(
          const Duration(milliseconds: 900),
        );

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          final up = json['up'] as int? ?? 0;
          final down = json['down'] as int? ?? 0;

          _stats = _stats.copyWith(
            uploadBytesPerSec: up,
            downloadBytesPerSec: down,
            totalUploadBytes: _stats.totalUploadBytes + up,
            totalDownloadBytes: _stats.totalDownloadBytes + down,
          );
          _statsController.add(_stats);
        }
      } catch (_) {}
    });
  }

  void _stopTrafficMonitor() {
    _trafficTimer?.cancel();
    _trafficTimer = null;
    _apiClient?.close(force: true);
    _apiClient = null;
  }

  static Future<int> testLatency(Profile profile) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        profile.server,
        profile.port,
        timeout: const Duration(milliseconds: 3500),
      );
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }
}
