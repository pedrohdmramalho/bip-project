import 'package:flutter/material.dart';

class AnimatedAdCard extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedAdCard({super.key, required this.child, required this.index});

  @override
  State<AnimatedAdCard> createState() => _AnimatedAdCardState();
}

class _AnimatedAdCardState extends State<AnimatedAdCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 900 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _visible ? Offset.zero : const Offset(0, 0.1),
        child: widget.child,
      ),
    );
  }
}
