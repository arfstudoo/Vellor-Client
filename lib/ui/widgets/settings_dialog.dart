import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/autostart_manager.dart';
import 'logs_dialog.dart';
import 'smooth_scroll_wrapper.dart';

class SettingsDialog extends StatefulWidget {
  final bool autoConnect;
  final bool autoStart;
  final bool bypassRu;
  final List<String> splitApps;
  final bool tlsFragment;
  final bool killSwitch;
  final Function({
    required bool autoConnect,
    required bool autoStart,
    required bool bypassRu,
    required List<String> splitApps,
    required bool tlsFragment,
    required bool killSwitch,
  }) onSave;

  const SettingsDialog({
    super.key,
    required this.autoConnect,
    required this.autoStart,
    required this.bypassRu,
    required this.splitApps,
    this.tlsFragment = false,
    this.killSwitch = false,
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
  late bool _tlsFragment;
  late bool _killSwitch;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customAppController = TextEditingController();

  final List<Map<String, String>> _presetApps = const [
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
    _tlsFragment = widget.tlsFragment;
    _killSwitch = widget.killSwitch;
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
      tlsFragment: _tlsFragment,
      killSwitch: _killSwitch,
    );
    if (Platform.isWindows) {
      AutoStartManager.setEnabled(_autoStart);
    }
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
    final isWindows = Platform.isWindows;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: const Color(0xFF0C0C12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1E1E2A), width: 0.8),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 500 ? 12 : 24,
        vertical: 20,
      ),
      child: Container(
        width: 490,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Настройки',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF0F0F5),
                    letterSpacing: -0.2,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF222232), width: 0.6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: Color(0xFF8E8E9E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SmoothScrollWrapper(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  children: [
                    _buildSectionHeader('ОСНОВНЫЕ'),
                    if (isWindows)
                      _buildSwitchTile(
                        title: 'Запуск вместе с Windows',
                        subtitle: 'Автоматический запуск программы в свернутом виде в системный трей',
                        value: _autoStart,
                        onChanged: (v) => setState(() => _autoStart = v),
                      ),
                    _buildSwitchTile(
                      title: 'Автоматическое подключение',
                      subtitle: 'Устанавливать соединение с последним сервером сразу после запуска',
                      value: _autoConnect,
                      onChanged: (v) => setState(() => _autoConnect = v),
                    ),
                    const SizedBox(height: 10),
                    _buildSectionHeader('МАРШРУТИЗАЦИЯ И СЕТЬ'),
                    _buildSwitchTile(
                      title: 'Прямой доступ для РФ сайтов',
                      subtitle: 'Госуслуги, банки и российские сервисы открываются напрямую на высокой скорости',
                      value: _bypassRu,
                      onChanged: (v) => setState(() => _bypassRu = v),
                    ),
                    _buildSwitchTile(
                      title: 'Анти-блокировка (TLS Fragment)',
                      subtitle: 'Разбивка пакетов ClientHello для уверенного обхода блокировок ТСПУ и DPI операторов',
                      value: _tlsFragment,
                      onChanged: (v) => setState(() => _tlsFragment = v),
                    ),
                    const SizedBox(height: 10),
                    _buildSectionHeader('БЕЗОПАСНОСТЬ'),
                    _buildSwitchTile(
                      title: 'Аварийная блокировка (Kill Switch)',
                      subtitle: 'Моментально блокирует интернет при внезапном сбое или разрыве соединения',
                      value: _killSwitch,
                      onChanged: (v) => setState(() => _killSwitch = v),
                    ),
                    if (isWindows) ...[
                      const SizedBox(height: 10),
                      _buildSectionHeader('РАЗДЕЛЬНОЕ ТУННЕЛИРОВАНИЕ'),
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1C1C28), width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSplitActive
                                  ? 'Активно: только выбранные приложения идут через туннель'
                                  : 'Не активно: весь сетевой трафик системы идет через туннель',
                              style: TextStyle(
                                fontSize: 10.5,
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
                                  backgroundColor: const Color(0xFF171722),
                                  checkmarkColor: const Color(0xFF38BDF8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(
                                      color: isChecked
                                          ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                                          : const Color(0xFF262636),
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: TextField(
                                      controller: _customAppController,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFEDEDF2)),
                                      decoration: InputDecoration(
                                        hintText: 'Добавить процесс (например: game.exe)',
                                        hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF6B6B7C)),
                                        filled: true,
                                        fillColor: const Color(0xFF09090E),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF222230), width: 0.8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF222230), width: 0.8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                                        ),
                                      ),
                                      onSubmitted: (_) => _addCustomApp(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _addCustomApp,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1B26),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF28283A), width: 0.8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_rounded, size: 16, color: Color(0xFFE2E2EA)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_splitApps.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _splitApps
                                    .where((e) => !_presetApps.any((p) => p['exe'] == e))
                                    .map((custom) {
                                  return Chip(
                                    label: Text(custom, style: const TextStyle(fontSize: 9.5, color: Color(0xFFEDEDF2))),
                                    deleteIcon: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF8E8E9E)),
                                    onDeleted: () {
                                      setState(() => _splitApps.remove(custom));
                                    },
                                    backgroundColor: const Color(0xFF1D1D2B),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: const BorderSide(color: Color(0xFF2A2A3C), width: 0.6),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildSectionHeader('ДИАГНОСТИКА'),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const LogsDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1C1C28), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Журнал событий ядра (Логи sing-box)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFEDEDF2)),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6B6B7C)),
                          ],
                        ),
                      ),
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
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Отмена', style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 11.5)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  ),
                  child: const Text('Сохранить', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
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
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF646476),
          letterSpacing: 0.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1C1C28), width: 0.8),
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7E7E90),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFFE53935),
              activeThumbColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
