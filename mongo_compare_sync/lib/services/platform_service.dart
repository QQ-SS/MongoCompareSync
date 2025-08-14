import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 平台适配服务，用于处理平台特定的功能和UI调整
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  static PlatformService get instance => _instance;
  factory PlatformService() => _instance;

  PlatformService._internal();

  /// 判断当前平台是否为macOS
  bool get isMacOS => Platform.isMacOS;

  /// 判断当前平台是否为Windows
  bool get isWindows => Platform.isWindows;

  /// 获取平台特定的边距
  EdgeInsets getPlatformPadding({bool isDialog = false}) {
    if (isMacOS) {
      return isDialog ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);
    } else {
      return isDialog ? const EdgeInsets.all(20.0) : const EdgeInsets.all(12.0);
    }
  }

  /// 获取平台特定的圆角半径
  double getPlatformBorderRadius() {
    return isMacOS ? 8.0 : 4.0;
  }

  /// 获取平台特定的阴影高度
  double getPlatformElevation() {
    return isMacOS ? 2.0 : 4.0;
  }

  /// 获取平台特定的动画持续时间
  Duration getPlatformAnimationDuration() {
    return isMacOS
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 150);
  }

  /// 获取平台特定的字体
  String getPlatformFontFamily() {
    if (isMacOS) {
      return '.AppleSystemUIFont'; // macOS系统字体
    } else if (isWindows) {
      return 'Segoe UI'; // Windows系统字体
    } else {
      return 'Roboto'; // 默认字体
    }
  }

  /// 创建平台特定的按钮样式
  ButtonStyle getPlatformButtonStyle(BuildContext context) {
    final theme = Theme.of(context);

    if (isMacOS) {
      // macOS风格按钮
      return ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return theme.colorScheme.primary.withOpacity(0.8);
          }
          return theme.colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
      );
    } else {
      // Windows风格按钮
      return ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return theme.colorScheme.primary.withOpacity(0.7);
          }
          return theme.colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
      );
    }
  }

  /// 创建平台特定的卡片样式
  BoxDecoration getPlatformCardDecoration(BuildContext context) {
    final theme = Theme.of(context);

    if (isMacOS) {
      // macOS风格卡片
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      );
    } else {
      // Windows风格卡片
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
  }

  /// 获取平台特定的滚动物理特性
  ScrollPhysics getPlatformScrollPhysics() {
    if (isMacOS) {
      return const BouncingScrollPhysics();
    } else {
      return const ClampingScrollPhysics();
    }
  }

  /// 获取平台特定的快捷键
  Map<String, String> getPlatformShortcuts() {
    if (isMacOS) {
      return {'save': '⌘+S', 'refresh': '⌘+R', 'new': '⌘+N', 'delete': '⌘+⌫'};
    } else {
      return {
        'save': 'Ctrl+S',
        'refresh': 'F5',
        'new': 'Ctrl+N',
        'delete': 'Delete',
      };
    }
  }
}
