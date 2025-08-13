import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('应用设置', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.color_lens),
                    title: Text('主题设置'),
                    subtitle: Text('设置应用的主题颜色'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.language),
                    title: Text('语言设置'),
                    subtitle: Text('设置应用的显示语言'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('数据库设置', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.storage),
                    title: Text('默认连接超时'),
                    subtitle: Text('设置数据库连接的默认超时时间'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.data_array),
                    title: Text('批处理大小'),
                    subtitle: Text('设置数据同步时的批处理大小'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关于', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('版本信息'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.help),
                    title: Text('帮助与支持'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
