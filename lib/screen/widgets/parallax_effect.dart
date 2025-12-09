import 'package:flutter/material.dart';

/// Parallax scroll effect for premium modern feel
class ParallaxWidget extends StatefulWidget {
  final Widget child;
  final double speed;
  final ScrollController? scrollController;

  const ParallaxWidget({
    super.key,
    required this.child,
    this.speed = 0.5,
    this.scrollController,
  });

  @override
  State<ParallaxWidget> createState() => _ParallaxWidgetState();
}

class _ParallaxWidgetState extends State<ParallaxWidget> {
  late ScrollController _scrollController;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _offset = _scrollController.offset * widget.speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -_offset),
      child: widget.child,
    );
  }
}

/// Animated gradient background with parallax
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFFF5F7FA),
                  const Color(0xFFE8F4F8),
                  _controller.value,
                )!,
                const Color(0xFFE8EFF5),
                Color.lerp(
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                  _controller.value,
                )!.withOpacity(0.3),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
