import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final enableLogging = ref.watch(enableLoggingProvider);
    final maxDocuments = ref.watch(maxDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('应用设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 主题设置
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '外观',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('主题模式'),
                    subtitle: Text(
                      themeMode == ThemeMode.system
                          ? '跟随系统'
                          : themeMode == ThemeMode.light
                          ? '明亮模式'
                          : '暗黑模式',
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(themeModeProvider.notifier).state = value;
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('跟随系统'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('明亮模式'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('暗黑模式'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 比较设置
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '比较设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('最大加载文档数量'),
                    subtitle: const Text('比较时最多加载的文档数量，设置过大可能导致性能问题'),
                    trailing: DropdownButton<int>(
                      value: maxDocuments,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(maxDocumentsProvider.notifier).state = value;
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('无限制')),
                        DropdownMenuItem(value: 500, child: Text('500')),
                        DropdownMenuItem(value: 1000, child: Text('1000')),
                        DropdownMenuItem(value: 2000, child: Text('2000')),
                        DropdownMenuItem(value: 5000, child: Text('5000')),
                        DropdownMenuItem(value: 10000, child: Text('10000')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 其他设置
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '其他设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('启用日志记录'),
                    subtitle: const Text('记录应用操作日志，方便调试和问题排查'),
                    value: enableLogging,
                    onChanged: (value) {
                      ref.read(enableLoggingProvider.notifier).state = value;
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('查看日志文件'),
                    subtitle: const Text('查看应用程序的日志记录'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogViewerScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 版本信息
          const Center(
            child: Text(
              'MongoDB比较同步工具 v1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '© 2025 MongoCompareSync',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
