import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final pageSize = ref.watch(pageSizeProvider);
    final showObjectIds = ref.watch(showObjectIdsProvider);
    final caseSensitiveComparison = ref.watch(caseSensitiveComparisonProvider);
    final confirmBeforeSync = ref.watch(confirmBeforeSyncProvider);
    final enableLogging = ref.watch(enableLoggingProvider);

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

          // 数据显示设置
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据显示',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('每页显示文档数量'),
                    subtitle: Text('$pageSize'),
                    trailing: DropdownButton<int>(
                      value: pageSize,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(pageSizeProvider.notifier).state = value;
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('显示ObjectId'),
                    subtitle: const Text('在文档列表中显示MongoDB的ObjectId'),
                    value: showObjectIds,
                    onChanged: (value) {
                      ref.read(showObjectIdsProvider.notifier).state = value;
                    },
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
                  SwitchListTile(
                    title: const Text('区分大小写比较'),
                    subtitle: const Text('比较字符串时是否区分大小写'),
                    value: caseSensitiveComparison,
                    onChanged: (value) {
                      ref.read(caseSensitiveComparisonProvider.notifier).state =
                          value;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 同步设置
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '同步设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('同步前确认'),
                    subtitle: const Text('在执行同步操作前显示确认对话框'),
                    value: confirmBeforeSync,
                    onChanged: (value) {
                      ref.read(confirmBeforeSyncProvider.notifier).state =
                          value;
                    },
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
