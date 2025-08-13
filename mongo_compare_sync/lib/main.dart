import 'dart:async';
import 'package:flutter/material.dart';
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

    return MaterialApp(
      title: 'MongoDB比较同步工具',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // 蓝色主题
          secondary: const Color(0xFF607D8B), // 灰蓝色辅助色
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          secondary: const Color(0xFF607D8B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: themeMode, // 使用设置中的主题模式
      home: const HomeScreen(),
    );
  }
}
