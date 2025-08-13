import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/home_screen.dart';
import 'models/hive_adapters.dart';
import 'repositories/compare_rule_repository.dart';
import 'repositories/connection_repository.dart';
import 'services/mongo_service.dart';
import 'services/log_service.dart';
import 'services/error_service.dart';
import 'services/platform_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化错误捕获
  final errorService = ErrorService();
  errorService.initErrorCapture();

  // 使用runZonedGuarded捕获未处理的异步错误
  runZonedGuarded(
    () async {
      try {
        // 初始化Hive
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);

        // 注册Hive适配器
        registerHiveAdapters();

        // 初始化规则存储库
        await CompareRuleRepository().init();

        // 初始化连接存储库
        final mongoService = MongoService();
        await ConnectionRepository(mongoService: mongoService).init();

        // 运行应用
        runApp(const ProviderScope(child: MongoCompareSyncApp()));
      } catch (e, stackTrace) {
        // 记录启动错误
        final logService = LogService();
        logService.fatal('应用启动失败', e, stackTrace);
        rethrow; // 重新抛出异常，让Flutter显示错误屏幕
      }
    },
    (error, stackTrace) {
      // 处理未捕获的异步错误
      final logService = LogService();
      logService.fatal('未捕获的异步错误', error, stackTrace);
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
          elevation: MaterialStateProperty.all(elevation),
          shape: MaterialStateProperty.all(
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
        thickness: MaterialStateProperty.all(8.0),
        thumbVisibility: MaterialStateProperty.all(true),
        radius: Radius.circular(borderRadius),
      ),
    );

    final darkThemeWithPlatformStyles = darkTheme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: MaterialStateProperty.all(elevation),
          shape: MaterialStateProperty.all(
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
        thickness: MaterialStateProperty.all(8.0),
        thumbVisibility: MaterialStateProperty.all(true),
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
