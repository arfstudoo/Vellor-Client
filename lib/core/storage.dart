import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/profile.dart';
import '../models/subscription.dart';

class AppStorage {
  static Directory? _customDir;

  static Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      _customDir = Directory('${docDir.path}/Vellor');
      if (!_customDir!.existsSync()) {
        _customDir!.createSync(recursive: true);
      }
    }
  }

  static Directory getStorageDirectory() {
    if (_customDir != null) return _customDir!;

    final appData = Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Directory.current.path;
    final separator = Platform.isWindows ? '\\' : '/';
    final dir = Directory('$appData${separator}Vellor');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      final oldDir = Directory('$appData${separator}Tunyx');
      if (oldDir.existsSync()) {
        try {
          final oldConfig = File('${oldDir.path}${separator}app_state.json');
          if (oldConfig.existsSync()) {
            oldConfig.copySync('${dir.path}${separator}app_state.json');
          }
        } catch (_) {}
      }
    }
    return dir;
  }

  static File _getConfigFile() {
    final dir = getStorageDirectory();
    final separator = Platform.isWindows ? '\\' : '/';
    return File('${dir.path}${separator}app_state.json');
  }

  static Future<Map<String, dynamic>> loadState() async {
    try {
      final file = _getConfigFile();
      if (!file.existsSync()) {
        return {
          'subscriptions': <Subscription>[],
          'selectedProfileId': null,
          'bypassRu': false,
        };
      }
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final subs = <Subscription>[];
      if (data['subscriptions'] != null) {
        final list = data['subscriptions'] as List<dynamic>;
        for (final item in list) {
          subs.add(Subscription.fromJson(item as Map<String, dynamic>));
        }
      } else if (data['profiles'] != null) {
        final oldProfiles = (data['profiles'] as List<dynamic>)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
        if (oldProfiles.isNotEmpty) {
          subs.add(Subscription(
            id: 'legacy_sub',
            name: 'Моя подписка',
            url: '',
            lastUpdated: DateTime.now(),
            profiles: oldProfiles,
          ));
        }
      }

      return {
        'subscriptions': subs,
        'selectedProfileId': data['selectedProfileId'],
        'bypassRu': data['bypassRu'] ?? false,
        'mode': data['mode'] ?? 'tun',
        'autoConnect': data['autoConnect'] ?? false,
        'autoStart': data['autoStart'] ?? false,
        'splitApps': List<String>.from(data['splitApps'] ?? []),
      };
    } catch (_) {
      return {
        'subscriptions': <Subscription>[],
        'selectedProfileId': null,
        'bypassRu': false,
      };
    }
  }

  static Future<void> saveState({
    required List<Subscription> subscriptions,
    String? selectedProfileId,
    bool bypassRu = false,
    String mode = 'tun',
    bool autoConnect = false,
    bool autoStart = false,
    List<String> splitApps = const [],
  }) async {
    try {
      final file = _getConfigFile();
      final data = {
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'selectedProfileId': selectedProfileId,
        'bypassRu': bypassRu,
        'mode': mode,
        'autoConnect': autoConnect,
        'autoStart': autoStart,
        'splitApps': splitApps,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}
