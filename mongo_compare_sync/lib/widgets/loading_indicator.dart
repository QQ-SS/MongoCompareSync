import 'package:flutter/material.dart';
import '../services/platform_service.dart';

/// 加载指示器组件，根据平台显示不同的加载动画
class LoadingIndicator extends StatelessWidget {
  /// 加载提示文本
  final String? message;

  /// 指示器大小
  final double size;

  /// 指示器颜色
  final Color? color;

  /// 是否显示文本
  final bool showText;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 10,
              color: indicatorColor,
            ),
          ),
          if (showText && message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: textStyle),
          ],
        ],
      ),
    );
  }
}

/// 骨架屏组件，用于在加载数据时显示占位UI
class SkeletonLoader extends StatelessWidget {
  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角半径
  final double borderRadius;

  /// 是否显示动画效果
  final bool animate;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService.instance;
    final radius = platformService.getPlatformBorderRadius();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: animate
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEEEEEE),
                  Color(0xFFF5F5F5),
                  Color(0xFFEEEEEE),
                ],
                stops: [0.1, 0.5, 0.9],
              )
            : null,
      ),
      child: animate ? _AnimatedSkeleton(borderRadius: radius) : null,
    );
  }
}

/// 骨架屏动画组件
class _AnimatedSkeleton extends StatefulWidget {
  final double borderRadius;

  const _AnimatedSkeleton({required this.borderRadius});

  @override
  State<_AnimatedSkeleton> createState() => _AnimatedSkeletonState();
}

class _AnimatedSkeletonState extends State<_AnimatedSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏列表项组件
class SkeletonListItem extends StatelessWidget {
  /// 高度
  final double height;

  /// 是否显示头像
  final bool hasLeading;

  /// 是否显示尾部图标
  final bool hasTrailing;

  /// 行数
  final int lines;

  const SkeletonListItem({
    super.key,
    this.height = 72.0,
    this.hasLeading = true,
    this.hasTrailing = true,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService.instance;
    final padding = platformService.getPlatformPadding();

    return Container(
      padding: padding,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasLeading) ...[
            const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < lines; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  SkeletonLoader(
                    width: i == 0 ? double.infinity : 150,
                    height: 16,
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const SkeletonLoader(width: 24, height: 24, borderRadius: 4),
          ],
        ],
      ),
    );
  }
}
