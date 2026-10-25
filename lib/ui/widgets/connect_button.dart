import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/core_manager.dart';

class ConnectButton extends StatefulWidget {
  final CoreState state;
  final VoidCallback onTap;

  const ConnectButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  Timer? _durationTimer;
  DateTime? _connectedStartTime;
  Duration _elapsed = Duration.zero;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _updateState(widget.state);
  }

  void _updateState(CoreState state) {
    if (state == CoreState.connecting) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
      _stopTimer();
    } else if (state == CoreState.connected) {
      _spinController.stop();
      _spinController.reset();
      _startTimer();
    } else {
      _spinController.stop();
      _spinController.reset();
      _stopTimer();
    }
  }

  void _startTimer() {
    _connectedStartTime ??= DateTime.now();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _connectedStartTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_connectedStartTime!);
        });
      }
    });
    _elapsed = DateTime.now().difference(_connectedStartTime!);
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _connectedStartTime = null;
    _elapsed = Duration.zero;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void didUpdateWidget(covariant ConnectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _updateState(widget.state);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.state == CoreState.connected;
    final isConnecting = widget.state == CoreState.connecting;
    final isError = widget.state == CoreState.error;

    Color primaryColor;
    String statusText;
    Color statusColor;

    if (isConnected) {
      primaryColor = const Color(0xFFE53935);
      statusText = 'Подключено';
      statusColor = const Color(0xFF10B981);
    } else if (isConnecting) {
      primaryColor = const Color(0xFFF59E0B);
      statusText = 'Подключение...';
      statusColor = const Color(0xFFF59E0B);
    } else if (isError) {
      primaryColor = const Color(0xFFEF4444);
      statusText = 'Ошибка подключения';
      statusColor = const Color(0xFFEF4444);
    } else {
      primaryColor = const Color(0xFF262636);
      statusText = 'Нажмите для подключения';
      statusColor = _isHovered ? const Color(0xFFB0B0C0) : const Color(0xFF8E8E9E);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isPressed ? 0.94 : (_isHovered ? 1.02 : 1.0),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isConnected)
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.38),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),

                    if (isConnecting)
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(134, 134),
                            painter: _MotionBlurOrbitPainter(
                              progress: _spinController.value,
                              color: primaryColor,
                            ),
                          );
                        },
                      ),

                    if (!isConnected && !isConnecting)
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isHovered
                                ? const Color(0xFF2E2E3E)
                                : const Color(0xFF1B1B26),
                            width: 1.0,
                          ),
                        ),
                      ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.25, -0.35),
                          radius: 0.9,
                          colors: isConnected
                              ? [
                                  const Color(0xFF381418),
                                  const Color(0xFF200A0D),
                                  const Color(0xFF130406),
                                ]
                              : (isConnecting
                                  ? [
                                      const Color(0xFF2E2211),
                                      const Color(0xFF1A140A),
                                      const Color(0xFF100C06),
                                    ]
                                  : [
                                      _isHovered
                                          ? const Color(0xFF222230)
                                          : const Color(0xFF1B1B26),
                                      const Color(0xFF13131B),
                                      const Color(0xFF0C0C12),
                                    ]),
                        ),
                        border: Border.all(
                          color: isConnected
                              ? const Color(0xFFE53935).withValues(alpha: 0.85)
                              : (isConnecting
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.75)
                                  : (_isHovered
                                      ? const Color(0xFF3C3C52)
                                      : const Color(0xFF242434))),
                          width: 1.4,
                        ),
                        boxShadow: [
                          if (isConnected) ...[
                            BoxShadow(
                              color: const Color(0xFFE53935).withValues(alpha: 0.32),
                              blurRadius: 28,
                              spreadRadius: 1,
                            ),
                          ],
                          if (isConnecting) ...[
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
                              blurRadius: 22,
                              spreadRadius: 0,
                            ),
                          ],
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: isConnected
                              ? Column(
                                  key: const ValueKey('connected_content'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.power_settings_new_rounded,
                                      size: 30,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFE53935),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(_elapsed),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Consolas',
                                        letterSpacing: 0.6,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Icon(
                                  Icons.power_settings_new_rounded,
                                  key: ValueKey(isConnecting ? 'wait' : 'off'),
                                  size: 40,
                                  color: isConnecting
                                      ? const Color(0xFFFDE68A)
                                      : (_isHovered
                                          ? Colors.white
                                          : const Color(0xFF8E8E9E)),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            statusText,
            key: ValueKey<String>(statusText),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isConnected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MotionBlurOrbitPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MotionBlurOrbitPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, trackPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    const arcSweep = math.pi * 1.35;

    final blurGlowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: arcSweep,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.38),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
    canvas.drawArc(rect, 0.0, arcSweep, false, blurGlowPaint);

    final luminousPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: arcSweep,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.88),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawArc(rect, 0.0, arcSweep, false, luminousPaint);

    final corePaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: arcSweep,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    canvas.drawArc(rect, 0.0, arcSweep, false, corePaint);

    final headAngle = arcSweep;
    final headX = center.dx + radius * math.cos(headAngle);
    final headY = center.dy + radius * math.sin(headAngle);
    final headPos = Offset(headX, headY);

    final headBloom = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(headPos, 4.0, headBloom);

    final headCore = Paint()..color = Colors.white;
    canvas.drawCircle(headPos, 2.2, headCore);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotionBlurOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
