import 'package:flutter/material.dart';
import '../../core/autostart_manager.dart';
import 'logs_dialog.dart';
import 'smooth_scroll_wrapper.dart';

class SettingsDialog extends StatefulWidget {
  final bool autoConnect;
  final bool autoStart;
  final bool bypassRu;
  final List<String> splitApps;
  final Function({
    required bool autoConnect,
    required bool autoStart,
    required bool bypassRu,
    required List<String> splitApps,
  }) onSave;

  const SettingsDialog({
    super.key,
    required this.autoConnect,
    required this.autoStart,
    required this.bypassRu,
    required this.splitApps,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _autoConnect;
  late bool _autoStart;
  late bool _bypassRu;
  late List<String> _splitApps;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customAppController = TextEditingController();

  final List<Map<String, String>> _presetApps = [
    {'name': 'Discord', 'exe': 'discord.exe'},
    {'name': 'Telegram', 'exe': 'telegram.exe'},
    {'name': 'Google Chrome', 'exe': 'chrome.exe'},
    {'name': 'Microsoft Edge', 'exe': 'msedge.exe'},
    {'name': 'Firefox', 'exe': 'firefox.exe'},
    {'name': 'Steam', 'exe': 'steam.exe'},
  ];

  @override
  void initState() {
    super.initState();
    _autoConnect = widget.autoConnect;
    _autoStart = widget.autoStart;
    _bypassRu = widget.bypassRu;
    _splitApps = List<String>.from(widget.splitApps);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customAppController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      autoConnect: _autoConnect,
      autoStart: _autoStart,
      bypassRu: _bypassRu,
      splitApps: _splitApps,
    );
    AutoStartManager.setEnabled(_autoStart);
    Navigator.of(context).pop();
  }

  void _addCustomApp() {
    final text = _customAppController.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      final exe = text.endsWith('.exe') ? text : '$text.exe';
      if (!_splitApps.contains(exe)) {
        setState(() {
          _splitApps.add(exe);
          _customAppController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSplitActive = _splitApps.isNotEmpty;

    return Dialog(
      backgroundColor: const Color(0xFF101016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F1F2C), width: 0.8),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 580),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: Color(0xFFE2E2EA)),
                    SizedBox(width: 8),
                    Text(
                      'Настройки',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEDEDF2),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: const Color(0xFF8E8E9E),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SmoothScrollWrapper(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  children: [
                  _buildSectionHeader('Система и автозапуск'),
                  _buildSwitchTile(
                    title: 'Запускать вместе с Windows',
                    subtitle: 'Приложение автоматически свернется в трей при старте ПК',
                    value: _autoStart,
                    onChanged: (v) => setState(() => _autoStart = v),
                  ),
                  _buildSwitchTile(
                    title: 'Автоматическое подключение',
                    subtitle: 'Подключаться к последнему серверу сразу при запуске',
                    value: _autoConnect,
                    onChanged: (v) => setState(() => _autoConnect = v),
                  ),
                  _buildSwitchTile(
                    title: 'Обход сайтов РФ',
                    subtitle: 'Госуслуги, банки и сервисы РФ работают напрямую',
                    value: _bypassRu,
                    onChanged: (v) => setState(() => _bypassRu = v),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionHeader('Раздельное туннелирование (Split Tunneling)'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF222230), width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSplitActive
                              ? 'Включено: через VPN идут только выбранные программы'
                              : 'Выключено: весь трафик системы идет через VPN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSplitActive
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF8E8E9E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _presetApps.map((app) {
                            final exe = app['exe']!;
                            final isChecked = _splitApps.contains(exe);
                            return FilterChip(
                              label: Text(app['name']!),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isChecked
                                    ? const Color(0xFFEDEDF2)
                                    : const Color(0xFF7E7E90),
                              ),
                              selected: isChecked,
                              selectedColor: const Color(0xFF2B2544),
                              backgroundColor: const Color(0xFF191924),
                              checkmarkColor: const Color(0xFF38BDF8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isChecked
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                                      : const Color(0xFF282838),
                                  width: 0.8,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _splitApps.add(exe);
                                  } else {
                                    _splitApps.remove(exe);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: TextField(
                                  controller: _customAppController,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFEDEDF2)),
                                  decoration: InputDecoration(
                                    hintText: 'Добавить свой процесс (например: app.exe)',
                                    hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF6B6B7C)),
                                    filled: true,
                                    fillColor: const Color(0xFF0D0D12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFF222230)),
                                    ),
                                  ),
                                  onSubmitted: (_) => _addCustomApp(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: _addCustomApp,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              color: const Color(0xFFE2E2EA),
                              splashRadius: 16,
                              tooltip: 'Добавить',
                            ),
                          ],
                        ),
                        if (_splitApps.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            children: _splitApps
                                .where((e) => !_presetApps.any((p) => p['exe'] == e))
                                .map((custom) {
                              return Chip(
                                label: Text(custom, style: const TextStyle(fontSize: 9)),
                                deleteIcon: const Icon(Icons.close, size: 12),
                                onDeleted: () {
                                  setState(() => _splitApps.remove(custom));
                                },
                                backgroundColor: const Color(0xFF222230),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionHeader('Диагностика'),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const LogsDialog(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEDEDF2),
                      side: const BorderSide(color: Color(0xFF222232)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Журнал событий ядра (Логи sing-box)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена', style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Сохранить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7E7E90),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF222230), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF2),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7E7E90),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFE53935),
            activeThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
