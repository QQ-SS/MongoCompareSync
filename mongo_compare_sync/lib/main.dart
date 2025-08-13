import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/home_screen.dart';
import 'models/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  // 注册Hive适配器
  registerHiveAdapters();
  
  runApp(
    const ProviderScope(
      child: MongoCompareSyncApp(),
    ),
  );
}

class MongoCompareSyncApp extends StatelessWidget {
  const MongoCompareSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system, // 跟随系统主题
      home: const HomeScreen(),
    );
  }
}