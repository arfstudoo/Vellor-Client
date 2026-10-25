import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/vless_parser.dart';
import '../../models/profile.dart';
import '../../models/subscription.dart';
import '../../theme/vellor_theme.dart';
import 'country_flag.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final String? selectedProfileId;
  final Function(Profile) onSelectProfile;
  final VoidCallback onToggleExpand;
  final VoidCallback onRefresh;
  final VoidCallback onPingAll;
  final VoidCallback onDelete;
  final Function(String) onRename;
  final bool isPinging;
  final String searchQuery;
  final bool sortByPing;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.selectedProfileId,
    required this.onSelectProfile,
    required this.onToggleExpand,
    required this.onRefresh,
    required this.onPingAll,
    required this.onDelete,
    required this.onRename,
    this.isPinging = false,
    this.searchQuery = '',
    this.sortByPing = false,
  });

  void _openSupportUrl(String url) {
    try {
      Process.run('cmd', ['/c', 'start', '', url]);
    } catch (_) {}
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: subscription.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TunyxColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Переименовать', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 13, color: TunyxColors.textPrimary),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: TunyxColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                onRename(newName);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TunyxColors.redPrimary),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  String _formatTechDetails(Profile p) {
    if (p.protocol == 'vless') {
      return p.security == 'reality' ? 'VLESS Reality' : 'VLESS TLS';
    }
    if (p.protocol == 'hysteria2') return 'Hysteria 2';
    if (p.protocol == 'trojan') return 'Trojan';
    return 'Shadowsocks';
  }

  @override
  Widget build(BuildContext context) {
    final sub = subscription;

    List<Profile> displayProfiles = List<Profile>.from(sub.profiles);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      displayProfiles = displayProfiles.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.flag.toLowerCase().contains(q) ||
            p.server.toLowerCase().contains(q);
      }).toList();
    }
    if (sortByPing) {
      displayProfiles.sort((a, b) {
        final aLat = a.latencyMs > 0 ? a.latencyMs : 999999;
        final bLat = b.latencyMs > 0 ? b.latencyMs : 999999;
        return aLat.compareTo(bLat);
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E1E2A),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      sub.isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: const Color(0xFF8E8E9A),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                Expanded(
                  child: InkWell(
                    onTap: onToggleExpand,
                    borderRadius: BorderRadius.circular(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Color(0xFFF2F2F5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub.formattedSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7E7E8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      iconSize: 18,
                      color: const Color(0xFF8E8E9A),
                      splashRadius: 16,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Обновить подписку',
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      onPressed: isPinging ? null : onPingAll,
                      icon: const Icon(Icons.speed_rounded),
                      iconSize: 18,
                      color: isPinging
                          ? TunyxColors.yellowPing
                          : const Color(0xFF8E8E9A),
                      splashRadius: 16,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Проверить пинг',
                    ),
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF8E8E9A),
                        size: 18,
                      ),
                      color: const Color(0xFF1A1A24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF262636)),
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameDialog(context);
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          height: 34,
                          child: Text('Переименовать', style: TextStyle(fontSize: 12)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          height: 34,
                          child: Text(
                            'Удалить подписку',
                            style: TextStyle(fontSize: 12, color: TunyxColors.redBright),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Row(
              children: [

                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4C5D99),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'i',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'serif',
                        color: Color(0xFF8295D8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161622),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: const Color(0xFF2D2D42),
                        width: 0.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: sub.trafficProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF382F6B),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            sub.formattedTraffic,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Consolas',
                              color: Color(0xFFE2E2EA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Text(
                  'Истекает: ${sub.formattedExpire}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8E8E9A),
                  ),
                ),

                if (sub.supportUrl != null && sub.supportUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openSupportUrl(sub.supportUrl!),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.near_me_rounded,
                        size: 16,
                        color: Color(0xFF4E7AD8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (sub.isExpanded) ...[
            Container(
              height: 0.8,
              color: const Color(0xFF1C1C28),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: displayProfiles.length,
              itemBuilder: (context, index) {
                final p = displayProfiles[index];
                final isSelected = p.id == selectedProfileId;

                Color pingColor = TunyxColors.textMuted;
                if (p.latencyMs > 0) {
                  if (p.latencyMs < 120) {
                    pingColor = TunyxColors.greenPing;
                  } else if (p.latencyMs < 250) {
                    pingColor = TunyxColors.yellowPing;
                  } else {
                    pingColor = TunyxColors.redPing;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF181824)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2A2A3E)
                          : Colors.transparent,
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelectProfile(p),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            CountryFlag(
                              code: p.flag,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    VlessParser.stripEmojis(p.name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? TunyxColors.textPrimary
                                          : TunyxColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _formatTechDetails(p),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: TunyxColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.centerRight,
                              child: p.latencyMs > 0
                                  ? Text(
                                      '${p.latencyMs} мс',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'Consolas',
                                        fontWeight: FontWeight.w600,
                                        color: pingColor,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFE53935)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
