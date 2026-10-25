import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/vless_parser.dart';
import '../../models/subscription.dart';

class ImportDialog extends StatefulWidget {
  final Function(Subscription) onImport;

  const ImportDialog({
    super.key,
    required this.onImport,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _statusMessage = '';
  bool _isError = false;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleParse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Поле ввода не должно быть пустым';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isFetching = true;
      _statusMessage = text.startsWith('http')
          ? 'Загрузка списка серверов...'
          : 'Чтение конфигурации...';
      _isError = false;
    });

    try {
      if (text.startsWith('http://') || text.startsWith('https://')) {
        final sub = await VlessParser.fetchSubscription(text);
        if (!mounted) return;

        if (sub == null || sub.profiles.isEmpty) {
          setState(() {
            _isFetching = false;
            _statusMessage = 'Не удалось загрузить подписку по ссылке';
            _isError = true;
          });
          return;
        }

        widget.onImport(sub);
        Navigator.of(context).pop();
        return;
      }

      final profiles = VlessParser.parseSubscriptionOrLink(text);
      if (!mounted) return;

      if (profiles.isEmpty) {
        setState(() {
          _isFetching = false;
          _statusMessage = 'Не удалось распознать серверы в тексте';
          _isError = true;
        });
        return;
      }

      final sub = Subscription(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Мои серверы',
        url: '',
        lastUpdated: DateTime.now(),
        profiles: profiles,
      );

      widget.onImport(sub);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFetching = false;
        _statusMessage = 'Ошибка при разборе конфигурации';
        _isError = true;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _controller.text = data.text!.trim();
      await _handleParse();
    } else {
      setState(() {
        _statusMessage = 'Буфер обмена пуст';
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF222232),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.05),
              blurRadius: 28,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Добавить подписку',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: Color(0xFFF3F3F7),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Вставьте ссылку на подписку или ключ конфигурации',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7E7E94),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _isFetching ? null : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF171722),
                        border: Border.all(
                          color: const Color(0xFF262638),
                          width: 0.8,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF8E8E9E),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF09090E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? const Color(0xFFE53935).withValues(alpha: 0.8)
                        : const Color(0xFF1E1E2C),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      enabled: !_isFetching,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Consolas',
                        color: Color(0xFFEDEDF2),
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/sub/...\nvless://uuid@host:port...\nvmess://...',
                        hintStyle: TextStyle(
                          color: Color(0xFF4C4C60),
                          fontSize: 11.5,
                          fontFamily: 'Consolas',
                          height: 1.45,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                    if (_controller.text.isNotEmpty && !_isFetching)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {
                                _controller.clear();
                                setState(() {
                                  _statusMessage = '';
                                  _isError = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.backspace_outlined,
                                      size: 12,
                                      color: Color(0xFF7E7E94),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Очистить',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF7E7E94),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (_isFetching) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFF191924),
                    color: Color(0xFFE53935),
                    minHeight: 2.5,
                  ),
                ),
              ],

              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isError
                        ? const Color(0xFF221114)
                        : (_isFetching
                            ? const Color(0xFF221A0F)
                            : const Color(0xFF102219)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isError
                          ? const Color(0xFF42151B)
                          : (_isFetching
                              ? const Color(0xFF422E15)
                              : const Color(0xFF15422A)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline_rounded
                            : (_isFetching
                                ? Icons.sync_rounded
                                : Icons.check_circle_outline_rounded),
                        size: 14,
                        color: _isError
                            ? const Color(0xFFEF4444)
                            : (_isFetching
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _isError
                                ? const Color(0xFFFCA5A5)
                                : (_isFetching
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF6EE7B7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              Row(
                children: [

                  OutlinedButton.icon(
                    onPressed: _isFetching ? null : _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 14),
                    label: const Text('Из буфера'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4D4DE),
                      backgroundColor: const Color(0xFF161622),
                      side: const BorderSide(color: Color(0xFF26263A)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),

                  TextButton(
                    onPressed: _isFetching ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7E7E94),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 6),

                  ElevatedButton(
                    onPressed: _isFetching ? null : _handleParse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF2A2A38),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith((states) => 0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          if (!_isFetching)
                            BoxShadow(
                              color: const Color(0xFFE53935).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Text(_isFetching ? 'Загрузка...' : 'Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
