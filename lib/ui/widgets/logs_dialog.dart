import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/core_manager.dart';
import 'smooth_scroll_wrapper.dart';

class LogsDialog extends StatefulWidget {
  const LogsDialog({super.key});

  @override
  State<LogsDialog> createState() => _LogsDialogState();
}

class _LogsDialogState extends State<LogsDialog> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = CoreManager.instance.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log.trimRight());
          if (_logs.length > 500) _logs.removeAt(0);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _copyLogs() {
    final text = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Логи скопированы в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F1F2C), width: 0.8),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 600,
        height: 480,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Журнал событий ядра',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEDEDF2),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _logs.isEmpty ? null : _copyLogs,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: const Color(0xFF8E8E9E),
                      tooltip: 'Скопировать все',
                      splashRadius: 16,
                    ),
                    IconButton(
                      onPressed: () => setState(() => _logs.clear()),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      color: const Color(0xFF8E8E9E),
                      tooltip: 'Очистить',
                      splashRadius: 16,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: const Color(0xFF8E8E9E),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF181822), width: 0.8),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Пока нет записей. При подключении здесь появятся системные сообщения sing-box.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Color(0xFF555566)),
                        ),
                      )
                    : SmoothScrollWrapper(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                          final line = _logs[index];
                          Color textColor = const Color(0xFFB0B0C0);
                          if (line.toLowerCase().contains('fatal') ||
                              line.toLowerCase().contains('error') ||
                              line.toLowerCase().contains('panic')) {
                            textColor = const Color(0xFFEF4444);
                          } else if (line.toLowerCase().contains('warn')) {
                            textColor = const Color(0xFFF59E0B);
                          } else if (line.toLowerCase().contains('info')) {
                            textColor = const Color(0xFF38BDF8);
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                            child: SelectableText(
                              line,
                              style: TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 11,
                                height: 1.35,
                                color: textColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
