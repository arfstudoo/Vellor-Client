import 'dart:convert';

class Profile {
  final String id;
  final String name;
  final String protocol;
  final String server;
  final int port;
  final String uuid;
  final String security;
  final String flow;
  final String sni;
  final String pbk;
  final String sid;
  final String fp;
  final String network;
  final String path;
  final int latencyMs;
  final String flag;

  const Profile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    required this.uuid,
    this.security = 'reality',
    this.flow = '',
    this.sni = '',
    this.pbk = '',
    this.sid = '',
    this.fp = 'chrome',
    this.network = 'tcp',
    this.path = '',
    this.latencyMs = -1,
    this.flag = '🌐',
  });

  Profile copyWith({
    String? id,
    String? name,
    String? protocol,
    String? server,
    int? port,
    String? uuid,
    String? security,
    String? flow,
    String? sni,
    String? pbk,
    String? sid,
    String? fp,
    String? network,
    String? path,
    int? latencyMs,
    String? flag,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      uuid: uuid ?? this.uuid,
      security: security ?? this.security,
      flow: flow ?? this.flow,
      sni: sni ?? this.sni,
      pbk: pbk ?? this.pbk,
      sid: sid ?? this.sid,
      fp: fp ?? this.fp,
      network: network ?? this.network,
      path: path ?? this.path,
      latencyMs: latencyMs ?? this.latencyMs,
      flag: flag ?? this.flag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol,
      'server': server,
      'port': port,
      'uuid': uuid,
      'security': security,
      'flow': flow,
      'sni': sni,
      'pbk': pbk,
      'sid': sid,
      'fp': fp,
      'network': network,
      'path': path,
      'latencyMs': latencyMs,
      'flag': flag,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Сервер',
      protocol: json['protocol'] as String? ?? 'vless',
      server: json['server'] as String? ?? '',
      port: json['port'] as int? ?? 443,
      uuid: json['uuid'] as String? ?? '',
      security: json['security'] as String? ?? 'reality',
      flow: json['flow'] as String? ?? '',
      sni: json['sni'] as String? ?? '',
      pbk: json['pbk'] as String? ?? '',
      sid: json['sid'] as String? ?? '',
      fp: json['fp'] as String? ?? 'chrome',
      network: json['network'] as String? ?? 'tcp',
      path: json['path'] as String? ?? '',
      latencyMs: json['latencyMs'] as int? ?? -1,
      flag: json['flag'] as String? ?? '🌐',
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
