import 'package:flutter/material.dart';

/// 响应式布局组件，根据屏幕尺寸自动调整布局
class ResponsiveLayout extends StatelessWidget {
  /// 小屏幕布局（宽度 < 600）
  final Widget small;

  /// 中等屏幕布局（600 <= 宽度 < 1200）
  final Widget? medium;

  /// 大屏幕布局（宽度 >= 1200）
  final Widget? large;

  const ResponsiveLayout({
    super.key,
    required this.small,
    this.medium,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return large ?? medium ?? small;
        } else if (constraints.maxWidth >= 600) {
          return medium ?? small;
        } else {
          return small;
        }
      },
    );
  }
}

/// 响应式布局工具类
class ResponsiveLayoutUtil {
  /// 判断当前是否为小屏幕（宽度 < 600）
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// 判断当前是否为中等屏幕（600 <= 宽度 < 1200）
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// 判断当前是否为大屏幕（宽度 >= 1200）
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// 获取响应式内边距
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isMediumScreen(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// 获取响应式字体大小
  static double getResponsiveFontSize(
    BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    if (isLargeScreen(context)) {
      return large ?? medium ?? small;
    } else if (isMediumScreen(context)) {
      return medium ?? small;
    } else {
      return small;
    }
  }

  /// 获取响应式列数
  static int getResponsiveGridCount(BuildContext context) {
    if (isLargeScreen(context)) {
      return 4;
    } else if (isMediumScreen(context)) {
      return 3;
    } else {
      return 2;
    }
  }

  /// 获取响应式间距
  static double getResponsiveSpacing(BuildContext context) {
    if (isLargeScreen(context)) {
      return 24.0;
    } else if (isMediumScreen(context)) {
      return 16.0;
    } else {
      return 8.0;
    }
  }
}
