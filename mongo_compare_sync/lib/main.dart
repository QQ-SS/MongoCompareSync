import 'dart:async';
// 引入dart:io以使用File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 仍然需要获取应用文档目录
import 'screens/home_screen.dart';
import 'repositories/settings_repository.dart'; // 引入SettingsRepository
import 'services/mongo_service.dart'; // 引入MongoService
import 'repositories/compare_rule_repository.dart'; // 引入CompareRuleRepository
import 'repositories/connection_repository.dart'; // 引入ConnectionRepository
import 'services/log_service.dart';
import 'services/error_service.dart';
import 'services/platform_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  // 初始化错误捕获
  final errorService = ErrorService();
  errorService.initErrorCapture();

  // 使用runZonedGuarded捕获未处理的异步错误
  runZonedGuarded(
    () async {
      // 确保Flutter绑定初始化
      WidgetsFlutterBinding.ensureInitialized();
      try {
        // 初始化LogService
        await LogService.instance.init();

        // 初始化SettingsRepository (现在使用文件系统)
        await SettingsRepository().init();

        // 初始化MongoService
        final mongoService = MongoService();

        // 初始化CompareRuleRepository
        await CompareRuleRepository().init();

        // 初始化ConnectionRepository
        await ConnectionRepository(mongoService: mongoService).init();

        // 运行应用
        runApp(const ProviderScope(child: MongoCompareSyncApp()));
      } catch (e, stackTrace) {
        // 记录启动错误
        LogService.instance.fatal('应用启动失败', e, stackTrace);
        rethrow; // 重新抛出异常，让Flutter显示错误屏幕
      }
    },
    (error, stackTrace) {
      // 处理未捕获的异步错误
      LogService.instance.fatal('未捕获的异步错误', error, stackTrace);
    },
  );
}

class MongoCompareSyncApp extends ConsumerWidget {
  const MongoCompareSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题模式设置
    final themeMode = ref.watch(themeModeProvider);
    final platformService = PlatformService.instance;

    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.white,
        systemNavigationBarIconBrightness: themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    // 获取平台特定的字体
    final fontFamily = platformService.getPlatformFontFamily();
    final borderRadius = platformService.getPlatformBorderRadius();
    final elevation = platformService.getPlatformElevation();

    // 创建亮色主题
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // 蓝色主题
        secondary: const Color(0xFF607D8B), // 灰蓝色辅助色
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
    );

    // 创建暗色主题
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        secondary: const Color(0xFF607D8B),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
    );

    // 应用平台特定的样式
    final lightThemeWithPlatformStyles = lightTheme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(elevation),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8.0),
        thumbVisibility: WidgetStateProperty.all(true),
        radius: Radius.circular(borderRadius),
      ),
    );

    final darkThemeWithPlatformStyles = darkTheme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(elevation),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8.0),
        thumbVisibility: WidgetStateProperty.all(true),
        radius: Radius.circular(borderRadius),
      ),
    );

    return MaterialApp(
      title: 'MongoDB比较同步工具',
      theme: lightThemeWithPlatformStyles,
      darkTheme: darkThemeWithPlatformStyles,
      themeMode: themeMode, // 使用设置中的主题模式
      home: const HomeScreen(),
    );
  }
}
