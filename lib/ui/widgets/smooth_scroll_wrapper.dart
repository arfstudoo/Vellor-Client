import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SmoothScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double scrollFactor;

  const SmoothScrollWrapper({
    super.key,
    required this.child,
    required this.controller,
    this.scrollFactor = 1.25,
  });

  @override
  State<SmoothScrollWrapper> createState() => _SmoothScrollWrapperState();
}

class _SmoothScrollWrapperState extends State<SmoothScrollWrapper> {
  double _targetOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (event) {
            final pe = event as PointerScrollEvent;
            final c = widget.controller;
            if (!c.hasClients) return;

            final maxScroll = c.position.maxScrollExtent;
            final minScroll = c.position.minScrollExtent;

            if ((_targetOffset - c.offset).abs() > 220) {
              _targetOffset = c.offset;
            }

            final delta = pe.scrollDelta.dy * widget.scrollFactor;
            _targetOffset = (_targetOffset + delta).clamp(minScroll, maxScroll);

            c.animateTo(
              _targetOffset,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            );
          });
        }
      },
      child: widget.child,
    );
  }
}
