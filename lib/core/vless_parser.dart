import 'dart:convert';
import 'dart:io';
import '../models/profile.dart';
import '../models/subscription.dart';

class VlessParser {
  static int _idCounter = 0;

  static String _generateUniqueId(String protocol, String server, int port) {
    _idCounter++;
    final micros = DateTime.now().microsecondsSinceEpoch;
    final sanitizedServer = server.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${protocol}_${sanitizedServer}_${port}_${micros}_$_idCounter';
  }

  static String detectFlag(String rawName, String server) {
    var text = rawName;
    try {
      text = Uri.decodeComponent(rawName);
    } catch (_) {}

    final flagRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
    final match = flagRegex.firstMatch(text);
    if (match != null) {
      final runes = match.group(0)!.runes.toList();
      if (runes.length >= 2) {
        final c1 = String.fromCharCode(runes[0] - 0x1F1E6 + 65);
        final c2 = String.fromCharCode(runes[1] - 0x1F1E6 + 65);
        return '$c1$c2'.toUpperCase();
      }
    }

    final upper = ('$text $server').toUpperCase();
    if (upper.contains('ITALY') || upper.contains('ИТАЛИ') || upper.contains('.IT')) return 'IT';
    if (upper.contains('NETHERLAND') || upper.contains('AMSTERDAM') || upper.contains('ГОЛЛАНДИ') || upper.contains('НИДЕРЛАНД') || upper.contains('.NL')) return 'NL';
    if (upper.contains('ALBANIA') || upper.contains('АЛБАНИ') || upper.contains('.AL')) return 'AL';
    if (upper.contains('LITHUANIA') || upper.contains('VILNIUS') || upper.contains('ЛИТВ') || upper.contains('.LT')) return 'LT';
    if (upper.contains('GERMAN') || upper.contains('DE.') || upper.contains('ФРАНКФУРТ') || upper.contains('ГЕРМАНИ') || upper.contains('.DE')) return 'DE';
    if (upper.contains('SWEDEN') || upper.contains('ШВЕЦИ') || upper.contains('.SE')) return 'SE';
    if (upper.contains('AUSTRIA') || upper.contains('АВСТРИ') || upper.contains('.AT')) return 'AT';
    if (upper.contains('FRANCE') || upper.contains('ФРАНЦИ') || upper.contains('.FR')) return 'FR';
    if (upper.contains('NORWAY') || upper.contains('НОРВЕГИ') || upper.contains('.NO')) return 'NO';
    if (upper.contains('POLAND') || upper.contains('ПОЛЬШ') || upper.contains('.PL')) return 'PL';
    if (upper.contains('ESTONIA') || upper.contains('ЭСТОНИ') || upper.contains('.EE')) return 'EE';
    if (upper.contains('ENGLAND') || upper.contains('UK') || upper.contains('LONDON') || upper.contains('АНГЛИ') || upper.contains('ВЕЛИКОБРИТ')) return 'GB';
    if (upper.contains('USA') || upper.contains('UNITED STATES') || upper.contains('США') || upper.contains('.US')) return 'US';
    if (upper.contains('FINLAND') || upper.contains('ФИНЛЯНД') || upper.contains('.FI')) return 'FI';
    if (upper.contains('TURKEY') || upper.contains('ТУРЦИ') || upper.contains('.TR')) return 'TR';
    if (upper.contains('RUSSIA') || upper.contains('РОССИ') || upper.contains('.RU')) return 'RU';
    if (upper.contains('SWISS') || upper.contains('SWITZERLAND') || upper.contains('ШВЕЙЦАР') || upper.contains('.CH')) return 'CH';
    if (upper.contains('SPAIN') || upper.contains('ИСПАНИ') || upper.contains('.ES')) return 'ES';
    if (upper.contains('TURBO') || upper.contains('AUTO') || upper.contains('ЕВРОП')) return 'EU';

    return 'GLOBAL';
  }

  static String stripEmojis(String text) {
    var s = text;
    try {
      s = Uri.decodeComponent(text);
    } catch (_) {}

    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{FE00}-\u{FE0F}\u{200D}\u{200C}]',
      unicode: true,
    );
    s = s.replaceAll(emojiRegex, '').trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'^[|\-–—:/]\s*'), '').trim();
    s = s.replaceAll(RegExp(r'\s*[|\-–—:/]$'), '').trim();
    return s.isNotEmpty ? s : text;
  }

  static String formatName(String raw) {
    var text = raw;
    try {
      text = Uri.decodeComponent(raw);
    } catch (_) {}

    text = stripEmojis(text);

    final replacements = {
      'ITALY': 'Italy',
      'GERMANY': 'Germany',
      'SWEDEN': 'Sweden',
      'NETHERLANDS': 'Netherlands',
      'AUSTRIA': 'Austria',
      'FINLAND': 'Finland',
      'ESTONIA': 'Estonia',
      'LITHUANIA': 'Lithuania',
      'ALBANIA': 'Albania',
      'NORWAY': 'Norway',
      'POLAND': 'Poland',
      'FRANCE': 'France',
      'TURKEY': 'Turkey',
      'RUSSIA': 'Russia',
      'ENGLAND': 'England',
      'SWITZERLAND': 'Switzerland',
      'SPAIN': 'Spain',
      'АВАРИЙНЫЙ': 'Аварийный',
      'АВТО': 'Авто',
      'AUTO': 'Auto',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text.isNotEmpty ? text : raw;
  }

  static Future<Subscription?> fetchSubscription(String urlString) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    client.badCertificateCallback = (cert, host, port) => true;
    client.autoUncompress = true;

    try {
      final uri = Uri.parse(urlString.trim());
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set('User-Agent', 'v2rayN/6.39 clash.meta sing-box/1.14.0 (Windows NT 10.0; Win64; x64)');
      request.headers.set('Accept', '*/*');

      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        Stream<List<int>> stream = response;
        if (response.headers.value('content-encoding') == 'gzip') {
          stream = response.transform(gzip.decoder);
        }
        final body = await stream.transform(utf8.decoder).join();
        final profiles = parseSubscriptionOrLink(body);
        if (profiles.isEmpty) return null;

        var title = uri.host;
        final titleHeader = response.headers.value('profile-title');
        if (titleHeader != null && titleHeader.isNotEmpty) {
          if (titleHeader.startsWith('base64:')) {
            try {
              title = utf8.decode(base64.decode(titleHeader.substring(7).trim()), allowMalformed: true);
            } catch (_) {
              title = titleHeader;
            }
          } else {
            title = titleHeader;
          }
        }

        final updateInterval = int.tryParse(response.headers.value('profile-update-interval') ?? '') ?? 1;
        final supportUrl = response.headers.value('support-url');

        final userInfo = response.headers.value('subscription-userinfo') ?? '';
        int upload = 0;
        int download = 0;
        int total = 0;
        DateTime? expire;

        for (final part in userInfo.split(';')) {
          final kv = part.trim().split('=');
          if (kv.length == 2) {
            final k = kv[0].trim().toLowerCase();
            final v = int.tryParse(kv[1].trim()) ?? 0;
            if (k == 'upload') upload = v;
            if (k == 'download') download = v;
            if (k == 'total') total = v;
            if (k == 'expire') {
              expire = DateTime.fromMillisecondsSinceEpoch(v * 1000);
            }
          }
        }

        return Subscription(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${uri.host}',
          name: title,
          url: urlString.trim(),
          lastUpdated: DateTime.now(),
          autoUpdateIntervalHours: updateInterval,
          uploadBytes: upload,
          downloadBytes: download,
          totalBytes: total,
          expireDate: expire,
          supportUrl: supportUrl,
          profiles: profiles,
          isExpanded: true,
        );
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static List<Profile> parseSubscriptionOrLink(String rawInput) {
    final text = rawInput.trim();
    if (text.isEmpty) return [];

    if (text.contains('proxies:')) {
      final yamlProfiles = _parseClashYaml(text);
      if (yamlProfiles.isNotEmpty) return yamlProfiles;
    }

    final lines = text.split(RegExp(r'[\r\n]+'));
    final results = <Profile>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('vless://')) {
        final profile = parseVlessUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('vmess://')) {
        final profile = parseVmessUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('trojan://')) {
        final profile = parseTrojanUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('ss://')) {
        final profile = parseShadowsocksUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://')) {
        final profile = parseHysteria2Uri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('hysteria://')) {
        final profile = parseHysteria1Uri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('tuic://')) {
        final profile = parseTuicUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('socks5://') || trimmed.startsWith('socks://')) {
        final profile = parseSocksUri(trimmed);
        if (profile != null) results.add(profile);
      } else if (trimmed.startsWith('wireguard://') || trimmed.startsWith('wg://')) {
        final profile = parseWireguardUri(trimmed);
        if (profile != null) results.add(profile);
      } else {
        final decoded = _tryBase64Decode(trimmed);
        if (decoded != null && decoded != trimmed) {
          final subResults = parseSubscriptionOrLink(decoded);
          results.addAll(subResults);
        }
      }
    }

    return results;
  }

  static Profile? parseVlessUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'vless') return null;

      final uuid = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : '$server:$port';
      final name = formatName(rawName);
      final flag = detectFlag(rawName, server);

      final security = params['security'] ?? 'none';
      final flow = params['flow'] ?? '';
      final sni = params['sni'] ?? '';
      final pbk = params['pbk'] ?? '';
      final sid = params['sid'] ?? '';
      final fp = params['fp'] ?? 'chrome';
      final network = params['type'] ?? 'tcp';
      final path = params['path'] ?? '';

      return Profile(
        id: _generateUniqueId('vless', server, port),
        name: name,
        protocol: 'vless',
        server: server,
        port: port,
        uuid: uuid,
        security: security,
        flow: flow,
        sni: sni,
        pbk: pbk,
        sid: sid,
        fp: fp,
        network: network,
        path: path,
        flag: flag,
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseVmessUri(String uriString) {
    try {
      final base64Part = uriString.substring(8).trim();
      final decodedJson = _tryBase64Decode(base64Part);
      if (decodedJson != null && decodedJson.trim().startsWith('{')) {
        final data = jsonDecode(decodedJson) as Map<String, dynamic>;
        final server = (data['add'] ?? '').toString().trim();
        final port = int.tryParse(data['port']?.toString() ?? '') ?? 443;
        final uuid = (data['id'] ?? '').toString().trim();
        if (server.isEmpty || uuid.isEmpty) return null;

        final rawName = (data['ps'] ?? '').toString().trim().isNotEmpty
            ? data['ps'].toString().trim()
            : '$server:$port';
        final name = formatName(rawName);
        final flag = detectFlag(rawName, server);
        final network = (data['net'] ?? 'tcp').toString().trim();
        final path = (data['path'] ?? '').toString().trim();
        final host = (data['host'] ?? '').toString().trim();
        final tls = (data['tls'] ?? '').toString().trim();
        final sni = (data['sni'] ?? host).toString().trim();

        return Profile(
          id: _generateUniqueId('vmess', server, port),
          name: name,
          protocol: 'vmess',
          server: server,
          port: port,
          uuid: uuid,
          security: tls.isNotEmpty && tls != 'none' ? 'tls' : 'none',
          sni: sni.isNotEmpty ? sni : server,
          network: network,
          path: path,
          flag: flag,
        );
      }

      final uri = Uri.parse(uriString);
      if (uri.host.isNotEmpty) {
        final server = uri.host;
        final port = uri.port;
        final uuid = uri.userInfo;
        final params = uri.queryParameters;
        final rawName = uri.fragment.isNotEmpty ? uri.fragment : '$server:$port';
        return Profile(
          id: _generateUniqueId('vmess', server, port),
          name: formatName(rawName),
          protocol: 'vmess',
          server: server,
          port: port,
          uuid: uuid,
          security: params['security'] ?? 'none',
          sni: params['sni'] ?? server,
          network: params['type'] ?? 'tcp',
          path: params['path'] ?? '',
          flag: detectFlag(rawName, server),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Profile? parseTrojanUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'trojan') return null;

      final password = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : '$server:$port';
      final name = formatName(rawName);
      final flag = detectFlag(rawName, server);
      final sni = params['sni'] ?? server;
      final network = params['type'] ?? 'tcp';
      final path = params['path'] ?? '';

      return Profile(
        id: _generateUniqueId('trojan', server, port),
        name: name,
        protocol: 'trojan',
        server: server,
        port: port,
        uuid: password,
        security: 'tls',
        sni: sni,
        network: network,
        path: path,
        flag: flag,
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseShadowsocksUri(String uriString) {
    try {
      var withoutScheme = uriString.substring(5);
      String rawName = 'Shadowsocks';
      final hashIdx = withoutScheme.indexOf('#');
      if (hashIdx != -1) {
        rawName = withoutScheme.substring(hashIdx + 1);
        withoutScheme = withoutScheme.substring(0, hashIdx);
      }

      String name = formatName(rawName);
      String server = '';
      int port = 8388;
      String method = '2022-blake3-aes-128-gcm';
      String password = '';

      if (withoutScheme.contains('@')) {
        final atIdx = withoutScheme.indexOf('@');
        final userPart = withoutScheme.substring(0, atIdx);
        var hostPart = withoutScheme.substring(atIdx + 1);

        final qIdx = hostPart.indexOf('?');
        if (qIdx != -1) hostPart = hostPart.substring(0, qIdx);
        final slashIdx = hostPart.indexOf('/');
        if (slashIdx != -1) hostPart = hostPart.substring(0, slashIdx);

        final decodedUser = _tryBase64Decode(userPart) ?? userPart;
        final colonUser = decodedUser.indexOf(':');
        if (colonUser != -1) {
          method = decodedUser.substring(0, colonUser);
          password = decodedUser.substring(colonUser + 1);
        } else {
          password = decodedUser;
        }

        final colonHost = hostPart.lastIndexOf(':');
        if (colonHost != -1) {
          server = hostPart.substring(0, colonHost);
          port = int.tryParse(hostPart.substring(colonHost + 1)) ?? 8388;
        } else {
          server = hostPart;
        }
      } else {
        var cleaned = withoutScheme;
        final qIdx = cleaned.indexOf('?');
        if (qIdx != -1) cleaned = cleaned.substring(0, qIdx);
        final slashIdx = cleaned.indexOf('/');
        if (slashIdx != -1) cleaned = cleaned.substring(0, slashIdx);

        final decoded = _tryBase64Decode(cleaned);
        if (decoded != null && decoded.contains('@')) {
          final atIdx = decoded.indexOf('@');
          final userPart = decoded.substring(0, atIdx);
          final hostPart = decoded.substring(atIdx + 1);

          final colonUser = userPart.indexOf(':');
          if (colonUser != -1) {
            method = userPart.substring(0, colonUser);
            password = userPart.substring(colonUser + 1);
          } else {
            password = userPart;
          }

          final colonHost = hostPart.lastIndexOf(':');
          if (colonHost != -1) {
            server = hostPart.substring(0, colonHost);
            port = int.tryParse(hostPart.substring(colonHost + 1)) ?? 8388;
          } else {
            server = hostPart;
          }
        }
      }

      if (server.isEmpty) return null;
      final flag = detectFlag(rawName, server);

      return Profile(
        id: _generateUniqueId('ss', server, port),
        name: name,
        protocol: 'shadowsocks',
        server: server,
        port: port,
        uuid: '$method:$password',
        flag: flag,
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseHysteria2Uri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      final password = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      final rawName = uri.fragment.isNotEmpty
          ? uri.fragment
          : 'Hysteria-$server:$port';
      final name = formatName(rawName);
      final flag = detectFlag(rawName, server);
      final sni = params['sni'] ?? server;
      final insecure = params['insecure'] == '1' || params['insecure'] == 'true';
      final obfs = params['obfs'] ?? '';
      final obfsPassword = params['obfs-password'] ?? '';

      return Profile(
        id: _generateUniqueId('hy2', server, port),
        name: name,
        protocol: 'hysteria2',
        server: server,
        port: port,
        uuid: password,
        security: insecure ? 'insecure' : 'tls',
        flow: obfs.isNotEmpty ? '$obfs:$obfsPassword' : '',
        sni: sni,
        flag: flag,
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseHysteria1Uri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      final server = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      final auth = params['auth'] ?? uri.userInfo;
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : 'Hysteria-$server:$port';
      final sni = params['peer'] ?? params['sni'] ?? server;

      return Profile(
        id: _generateUniqueId('hy1', server, port),
        name: formatName(rawName),
        protocol: 'hysteria',
        server: server,
        port: port,
        uuid: auth,
        security: 'tls',
        sni: sni,
        flag: detectFlag(rawName, server),
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseTuicUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'tuic') return null;

      final server = uri.host;
      final port = uri.port;
      final userInfo = uri.userInfo;
      var uuid = userInfo;
      var password = '';
      if (userInfo.contains(':')) {
        final parts = userInfo.split(':');
        uuid = parts[0];
        password = parts[1];
      }

      final params = uri.queryParameters;
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : '$server:$port';
      final name = formatName(rawName);
      final flag = detectFlag(rawName, server);
      final sni = params['sni'] ?? server;

      return Profile(
        id: _generateUniqueId('tuic', server, port),
        name: name,
        protocol: 'tuic',
        server: server,
        port: port,
        uuid: uuid,
        security: 'tls',
        sni: sni,
        path: password,
        flag: flag,
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseSocksUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      final server = uri.host;
      final port = uri.port != 0 ? uri.port : 1080;
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : 'Socks-$server:$port';

      return Profile(
        id: _generateUniqueId('socks', server, port),
        name: formatName(rawName),
        protocol: 'socks',
        server: server,
        port: port,
        uuid: uri.userInfo,
        flag: detectFlag(rawName, server),
      );
    } catch (_) {
      return null;
    }
  }

  static Profile? parseWireguardUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      final server = uri.host;
      final port = uri.port != 0 ? uri.port : 51820;
      final privateKey = uri.userInfo;
      final params = uri.queryParameters;
      final peerPublicKey = params['publickey'] ?? params['public_key'] ?? '';
      final address = params['address'] ?? params['ip'] ?? '10.0.0.2/32';
      final rawName = uri.fragment.isNotEmpty ? uri.fragment : 'WireGuard-$server:$port';

      return Profile(
        id: _generateUniqueId('wg', server, port),
        name: formatName(rawName),
        protocol: 'wireguard',
        server: server,
        port: port,
        uuid: privateKey,
        pbk: peerPublicKey,
        sid: address,
        flag: detectFlag(rawName, server),
      );
    } catch (_) {
      return null;
    }
  }

  static List<Profile> _parseClashYaml(String yamlText) {
    final results = <Profile>[];
    try {
      final lines = yamlText.split(RegExp(r'[\r\n]+'));
      bool inProxies = false;
      Map<String, String> current = {};

      void flushCurrent() {
        if (current.isNotEmpty && current.containsKey('server') && current.containsKey('type')) {
          final type = current['type']!.toLowerCase();
          final server = current['server']!;
          final port = int.tryParse(current['port'] ?? '') ?? 443;
          final name = formatName(current['name'] ?? '$server:$port');
          final flag = detectFlag(name, server);

          if (type == 'vless') {
            results.add(Profile(
              id: _generateUniqueId('vless', server, port),
              name: name,
              protocol: 'vless',
              server: server,
              port: port,
              uuid: current['uuid'] ?? '',
              security: current['reality-opts'] != null || current['public-key'] != null ? 'reality' : (current['tls'] == 'true' ? 'tls' : 'none'),
              sni: current['servername'] ?? current['sni'] ?? server,
              pbk: current['public-key'] ?? '',
              sid: current['short-id'] ?? '',
              network: current['network'] ?? 'tcp',
              path: current['path'] ?? '',
              flag: flag,
            ));
          } else if (type == 'vmess') {
            results.add(Profile(
              id: _generateUniqueId('vmess', server, port),
              name: name,
              protocol: 'vmess',
              server: server,
              port: port,
              uuid: current['uuid'] ?? '',
              security: current['tls'] == 'true' ? 'tls' : 'none',
              sni: current['servername'] ?? current['sni'] ?? server,
              network: current['network'] ?? 'tcp',
              path: current['path'] ?? '',
              flag: flag,
            ));
          } else if (type == 'trojan') {
            results.add(Profile(
              id: _generateUniqueId('trojan', server, port),
              name: name,
              protocol: 'trojan',
              server: server,
              port: port,
              uuid: current['password'] ?? '',
              security: 'tls',
              sni: current['sni'] ?? current['servername'] ?? server,
              network: current['network'] ?? 'tcp',
              path: current['path'] ?? '',
              flag: flag,
            ));
          } else if (type == 'ss') {
            final cipher = current['cipher'] ?? '2022-blake3-aes-128-gcm';
            final pass = current['password'] ?? '';
            results.add(Profile(
              id: _generateUniqueId('ss', server, port),
              name: name,
              protocol: 'shadowsocks',
              server: server,
              port: port,
              uuid: '$cipher:$pass',
              flag: flag,
            ));
          } else if (type == 'hysteria2' || type == 'hy2') {
            results.add(Profile(
              id: _generateUniqueId('hy2', server, port),
              name: name,
              protocol: 'hysteria2',
              server: server,
              port: port,
              uuid: current['password'] ?? '',
              security: 'tls',
              sni: current['sni'] ?? server,
              flag: flag,
            ));
          }
        }
        current = {};
      }

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed == 'proxies:' || trimmed.startsWith('proxies:')) {
          inProxies = true;
          continue;
        }
        if (inProxies && !line.startsWith(' ') && !line.startsWith('\t') && trimmed.endsWith(':')) {
          break;
        }
        if (inProxies) {
          if (trimmed.startsWith('-')) {
            flushCurrent();
          }
          final clean = trimmed.replaceFirst(RegExp(r'^-\s*'), '').trim();
          final colonIdx = clean.indexOf(':');
          if (colonIdx != -1) {
            final key = clean.substring(0, colonIdx).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '');
            var val = clean.substring(colonIdx + 1).trim();
            val = val.replaceAll(RegExp(r'''^["']|["']$'''), '');
            if (key.isNotEmpty && val.isNotEmpty) {
              current[key] = val;
            }
          }
        }
      }
      flushCurrent();
    } catch (_) {}
    return results;
  }

  static String? _tryBase64Decode(String input) {
    try {
      var normalized = input.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64.decode(normalized), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
