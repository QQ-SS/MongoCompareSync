import 'package:flutter/material.dart';

/// 骨架屏加载组件
/// 用于在数据加载过程中显示占位UI
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.baseColor ??
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2);
    final highlightColor =
        widget.highlightColor ??
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _animation.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏列表项
/// 用于在列表加载过程中显示占位UI
class SkeletonListItem extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool hasLeading;
  final bool hasTrailing;

  const SkeletonListItem({
    super.key,
    this.height = 60,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.hasLeading = true,
    this.hasTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonLoader(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: borderRadius,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 120,
                  height: 12,
                  borderRadius: borderRadius,
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            SkeletonLoader(width: 24, height: 24, borderRadius: 4),
          ],
        ],
      ),
    );
  }
}

/// 骨架屏卡片
/// 用于在卡片加载过程中显示占位UI
class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final int lines;
  final double lineHeight;
  final double lineSpacing;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.all(16),
    this.lines = 3,
    this.lineHeight = 16,
    this.lineSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: width * 0.7,
            height: lineHeight + 4,
            borderRadius: borderRadius,
          ),
          SizedBox(height: lineSpacing * 1.5),
          ...List.generate(
            lines - 1,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: lineSpacing),
              child: SkeletonLoader(
                width: width * (index.isEven ? 0.9 : 0.8),
                height: lineHeight,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
