import 'package:flutter/material.dart';

class FloatingHeart extends StatefulWidget {
  final String emoji;
  final double xDrift;
  final VoidCallback onComplete;

  const FloatingHeart({
    super.key,
    required this.emoji,
    required this.xDrift,
    required this.onComplete,
  });

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward().whenComplete(widget.onComplete);

    _y = Tween<double>(begin: 0, end: -240)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.translate(
        offset: Offset(widget.xDrift * _ctrl.value, _y.value),
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 30)),
          ),
        ),
      ),
    );
  }
}
