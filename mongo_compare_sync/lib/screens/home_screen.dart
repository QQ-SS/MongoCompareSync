import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/connection_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const ConnectionScreen(),
    const CompareScreen(),
    const SettingsScreen(),
  ];

  // 底部导航栏项目
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.storage), label: '连接管理'),
    const BottomNavigationBarItem(
      icon: Icon(Icons.compare_arrows),
      label: '比较同步',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MongoDB比较同步工具'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
