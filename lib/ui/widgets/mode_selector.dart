import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const ModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 420;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF101016),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A1A24),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            id: 'tun',
            title: 'TUN',
            badge: 'Sing-box',
            icon: Icons.shield_outlined,
            showBadge: !isCompact,
          ),
          const SizedBox(width: 3),
          _buildItem(
            id: 'proxy',
            title: 'Прокси',
            badge: 'Xray',
            icon: Icons.language_rounded,
            showBadge: !isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String id,
    required String title,
    required String badge,
    required IconData icon,
    required bool showBadge,
  }) {
    final isSelected = selectedMode == id;

    return InkWell(
      onTap: () => onModeChanged(id),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: showBadge ? 8 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E2E40) : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFFE2E2EA) : const Color(0xFF727282),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFFF2F2F5) : const Color(0xFF888898),
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF28283A)
                      : const Color(0xFF161620),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF9E9EB2)
                        : const Color(0xFF5A5A6A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
