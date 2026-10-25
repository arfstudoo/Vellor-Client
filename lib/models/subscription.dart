import 'dart:convert';
import 'package:intl/intl.dart';
import 'profile.dart';

class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdated;
  final int autoUpdateIntervalHours;
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final DateTime? expireDate;
  final String? supportUrl;
  final List<Profile> profiles;
  final bool isExpanded;

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
    this.autoUpdateIntervalHours = 1,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes = 0,
    this.expireDate,
    this.supportUrl,
    required this.profiles,
    this.isExpanded = true,
  });

  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    DateTime? lastUpdated,
    int? autoUpdateIntervalHours,
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    DateTime? expireDate,
    String? supportUrl,
    List<Profile>? profiles,
    bool? isExpanded,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      autoUpdateIntervalHours:
          autoUpdateIntervalHours ?? this.autoUpdateIntervalHours,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      expireDate: expireDate ?? this.expireDate,
      supportUrl: supportUrl ?? this.supportUrl,
      profiles: profiles ?? this.profiles,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  String get formattedSubtitle {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final dateStr = dateFormat.format(lastUpdated.toLocal());
    return '$dateStr | Автообновление - $autoUpdateIntervalHoursч.';
  }

  String get formattedTraffic {
    final usedBytes = uploadBytes + downloadBytes;
    final usedStr = _formatBytes(usedBytes);

    if (totalBytes <= 0) {
      return '$usedStr / ∞';
    }
    final totalStr = _formatBytes(totalBytes);
    return '$usedStr / $totalStr';
  }

  double get trafficProgress {
    if (totalBytes <= 0) return 0.05;
    final used = uploadBytes + downloadBytes;
    final progress = used / totalBytes;
    return progress.clamp(0.0, 1.0);
  }

  String get formattedExpire {
    if (expireDate == null) return 'Бессрочно';
    final dateFormat = DateFormat('dd.MM.yyyy');
    return dateFormat.format(expireDate!.toLocal());
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'lastUpdated': lastUpdated.toIso8601String(),
      'autoUpdateIntervalHours': autoUpdateIntervalHours,
      'uploadBytes': uploadBytes,
      'downloadBytes': downloadBytes,
      'totalBytes': totalBytes,
      'expireDate': expireDate?.toIso8601String(),
      'supportUrl': supportUrl,
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'isExpanded': isExpanded,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Подписка',
      url: json['url'] as String? ?? '',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
      autoUpdateIntervalHours: json['autoUpdateIntervalHours'] as int? ?? 1,
      uploadBytes: json['uploadBytes'] as int? ?? 0,
      downloadBytes: json['downloadBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      expireDate: json['expireDate'] != null
          ? DateTime.tryParse(json['expireDate'] as String)
          : null,
      supportUrl: json['supportUrl'] as String?,
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((e) => Profile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isExpanded: json['isExpanded'] as bool? ?? true,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
