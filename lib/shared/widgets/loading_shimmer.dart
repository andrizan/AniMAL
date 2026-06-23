import 'package:flutter/material.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 120.0,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          child: SizedBox(
            height: itemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShimmerBlock(
                  width: 80,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBlock(
                          width: double.infinity,
                          height: 14,
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                        const SizedBox(height: 6),
                        _ShimmerBlock(
                          width: 140,
                          height: 11,
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: List.generate(3, (_) {
                            return _ShimmerBlock(
                              width: 48,
                              height: 16,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              radius: BorderRadius.circular(3),
                            );
                          }),
                        ),
                        const Spacer(),
                        _ShimmerBlock(
                          width: 100,
                          height: 11,
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    this.width,
    this.height,
    required this.baseColor,
    required this.highlightColor,
    this.radius,
  });

  final double? width;
  final double? height;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius? radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = ColorTween(
      begin: widget.baseColor,
      end: widget.highlightColor,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height ?? _defaultHeight,
          decoration: BoxDecoration(
            color: _animation.value,
            borderRadius: widget.radius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  double get _defaultHeight =>
      widget.width != null && widget.width! < 100 ? 16 : 24;
}
