import 'dart:convert';
import '../models/profile.dart';

class ConfigGenerator {
  static String generateSingBoxConfig({
    required Profile profile,
    required bool bypassRu,
    bool enableTun = true,
    List<String> splitTunnelingApps = const [],
    int mixedPort = 20808,
    int apiPort = 9090,
  }) {
    final Map<String, dynamic> outbound = _buildProxyOutbound(profile);

    final routeRules = <Map<String, dynamic>>[
      {
        'action': 'hijack-dns',
        'protocol': 'dns',
      },
      {
        'action': 'sniff',
      },
      {
        'ip_is_private': true,
        'outbound': 'direct',
      },
    ];

    const russianDomains = [
      'ru',
      '.ru',
      'su',
      '.su',
      'xn--p1ai',
      '.xn--p1ai',
      'moscow',
      '.moscow',
      'vk.com',
      'vkvideo.ru',
      'ok.ru',
      'mail.ru',
      'yandex.ru',
      'yandex.net',
      'ya.ru',
      'dzen.ru',
      'kinopoisk.ru',
      'gosuslugi.ru',
      'sberbank.ru',
      'sber.ru',
      'tinkoff.ru',
      'tbank.ru',
      'vtb.ru',
      'alfabank.ru',
      'raiffeisen.ru',
      'gazprombank.ru',
      'ozon.ru',
      'wildberries.ru',
      'avito.ru',
      'rutube.ru',
      '2gis.ru',
      'hh.ru',
      'auto.ru',
      'cian.ru',
      'mos.ru',
      'nalog.gov.ru',
      'pochta.ru',
      'rzd.ru',
      'rambler.ru',
      'championat.com',
      'sportbox.ru',
      'kassir.ru',
    ];

    if (bypassRu) {
      routeRules.add({
        'domain_suffix': russianDomains,
        'outbound': 'direct',
      });
    }

    if (splitTunnelingApps.isNotEmpty) {
      final expandedApps = <String>{};
      for (final app in splitTunnelingApps) {
        final lower = app.trim().toLowerCase();
        if (lower.isEmpty) continue;
        expandedApps.add(lower);
        if (lower == 'discord.exe') {
          expandedApps.add('discordcanary.exe');
          expandedApps.add('discordptb.exe');
        } else if (lower == 'steam.exe') {
          expandedApps.add('steamwebhelper.exe');
          expandedApps.add('steamservice.exe');
        } else if (lower == 'telegram.exe') {
          expandedApps.add('telegram.exe');
        }
      }

      routeRules.add({
        'process_name': expandedApps.toList(),
        'outbound': 'proxy',
      });
      routeRules.add({
        'outbound': 'direct',
      });
    }

    final inbounds = <Map<String, dynamic>>[];

    if (enableTun) {
      inbounds.add({
        'type': 'tun',
        'tag': 'tun-in',
        'interface_name': 'VellorTun',
        'address': ['172.19.0.1/30'],
        'mtu': 1500,
        'auto_route': true,
        'strict_route': false,
        'stack': 'gvisor',
      });
    }

    inbounds.add({
      'type': 'mixed',
      'tag': 'mixed-in',
      'listen': '127.0.0.1',
      'listen_port': mixedPort,
    });

    final config = {
      'log': {
        'level': 'warn',
        'timestamp': true,
      },
      'dns': {
        'servers': [
          {
            'tag': 'remote-dns',
            'type': 'tls',
            'server': '1.1.1.1',
            'detour': 'proxy',
          },
          {
            'tag': 'local-dns',
            'type': 'udp',
            'server': '77.88.8.8',
            'server_port': 53,
          },
        ],
        'rules': [
          if (bypassRu)
            {
              'domain_suffix': russianDomains,
              'server': 'local-dns',
            },
        ],
        'strategy': 'prefer_ipv4',
        'reverse_mapping': true,
      },
      'inbounds': inbounds,
      'outbounds': [
        outbound,
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        },
      ],
      'route': {
        'rules': routeRules,
        'default_domain_resolver': 'local-dns',
        'auto_detect_interface': true,
      },
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:$apiPort',
          'secret': '',
        },
      },
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildProxyOutbound(Profile p) {
    if (p.protocol == 'vless') {
      final isReality = p.security == 'reality' || p.pbk.isNotEmpty;
      final tlsConfig = <String, dynamic>{
        'enabled': true,
        'server_name': p.sni.isNotEmpty ? p.sni : p.server,
        'utls': {
          'enabled': true,
          'fingerprint': p.fp.isNotEmpty ? p.fp : 'chrome',
        },
      };

      if (isReality) {
        tlsConfig['reality'] = {
          'enabled': true,
          'public_key': p.pbk,
          'short_id': p.sid,
        };
      }

      final outbound = <String, dynamic>{
        'type': 'vless',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'uuid': p.uuid,
        'tls': tlsConfig,
      };

      if (p.flow.isNotEmpty) {
        outbound['flow'] = p.flow;
      }

      if (p.network == 'ws') {
        outbound['transport'] = {
          'type': 'ws',
          'path': p.path.isNotEmpty ? p.path : '/',
        };
      } else if (p.network == 'grpc') {
        outbound['transport'] = {
          'type': 'grpc',
          'service_name': p.path,
        };
      }

      return outbound;
    }

    if (p.protocol == 'vmess') {
      final outbound = <String, dynamic>{
        'type': 'vmess',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'uuid': p.uuid,
        'security': 'auto',
        'alter_id': 0,
      };

      if (p.security == 'tls') {
        outbound['tls'] = {
          'enabled': true,
          'server_name': p.sni.isNotEmpty ? p.sni : p.server,
        };
      }

      if (p.network == 'ws') {
        outbound['transport'] = {
          'type': 'ws',
          'path': p.path.isNotEmpty ? p.path : '/',
        };
      } else if (p.network == 'grpc') {
        outbound['transport'] = {
          'type': 'grpc',
          'service_name': p.path,
        };
      }

      return outbound;
    }

    if (p.protocol == 'trojan') {
      final outbound = <String, dynamic>{
        'type': 'trojan',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'password': p.uuid,
        'tls': {
          'enabled': true,
          'server_name': p.sni.isNotEmpty ? p.sni : p.server,
        },
      };

      if (p.network == 'ws') {
        outbound['transport'] = {
          'type': 'ws',
          'path': p.path.isNotEmpty ? p.path : '/',
        };
      } else if (p.network == 'grpc') {
        outbound['transport'] = {
          'type': 'grpc',
          'service_name': p.path,
        };
      }

      return outbound;
    }

    if (p.protocol == 'tuic') {
      return {
        'type': 'tuic',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'uuid': p.uuid,
        'password': p.path,
        'congestion_control': 'bbr',
        'tls': {
          'enabled': true,
          'server_name': p.sni.isNotEmpty ? p.sni : p.server,
          'alpn': ['h3'],
        },
      };
    }

    if (p.protocol == 'hysteria2') {
      final outbound = <String, dynamic>{
        'type': 'hysteria2',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'password': p.uuid,
        'tls': {
          'enabled': true,
          'server_name': p.sni.isNotEmpty ? p.sni : p.server,
          if (p.security == 'insecure') 'insecure': true,
        },
      };

      if (p.flow.isNotEmpty && p.flow.contains(':')) {
        final colonIdx = p.flow.indexOf(':');
        outbound['obfs'] = {
          'type': p.flow.substring(0, colonIdx),
          'password': p.flow.substring(colonIdx + 1),
        };
      }

      return outbound;
    }

    if (p.protocol == 'hysteria') {
      return {
        'type': 'hysteria',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'auth_str': p.uuid,
        'tls': {
          'enabled': true,
          'server_name': p.sni.isNotEmpty ? p.sni : p.server,
        },
      };
    }

    if (p.protocol == 'socks') {
      final outbound = <String, dynamic>{
        'type': 'socks',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
      };
      if (p.uuid.isNotEmpty && p.uuid.contains(':')) {
        final colon = p.uuid.indexOf(':');
        outbound['username'] = p.uuid.substring(0, colon);
        outbound['password'] = p.uuid.substring(colon + 1);
      }
      return outbound;
    }

    if (p.protocol == 'wireguard') {
      return {
        'type': 'wireguard',
        'tag': 'proxy',
        'server': p.server,
        'server_port': p.port,
        'private_key': p.uuid,
        'peer_public_key': p.pbk,
        'local_address': [p.sid.isNotEmpty ? p.sid : '10.0.0.2/32'],
      };
    }

    var method = '2022-blake3-aes-128-gcm';
    var password = p.uuid;
    if (p.uuid.contains(':')) {
      final colonIdx = p.uuid.indexOf(':');
      method = p.uuid.substring(0, colonIdx);
      password = p.uuid.substring(colonIdx + 1);
    }

    return {
      'type': 'shadowsocks',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'method': method,
      'password': password,
    };
  }
}
