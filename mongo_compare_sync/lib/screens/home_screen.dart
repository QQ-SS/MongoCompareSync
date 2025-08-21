import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/connection_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/responsive_layout.dart';

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

  // 页面标题
  final List<String> _pageTitles = ['连接管理', '比较同步', '设置'];

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
    ResponsiveLayoutUtil.isLargeScreen(context);
    ResponsiveLayoutUtil.isMediumScreen(context);

    // 为大屏幕创建侧边导航栏
    Widget buildNavigationRail() {
      return NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        labelType: NavigationRailLabelType.all,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.storage),
            label: const Text('连接管理'),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.compare_arrows),
            label: const Text('比较同步'),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.settings),
            label: const Text('设置'),
          ),
        ],
      );
    }

    // 响应式布局
    return ResponsiveLayout(
      // 小屏幕布局 - 使用底部导航栏
      small: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitles[_selectedIndex]),
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
          type: BottomNavigationBarType.fixed,
        ),
      ),

      // 中等屏幕布局 - 使用侧边导航栏
      medium: Scaffold(
        body: Row(
          children: [
            buildNavigationRail(),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_pageTitles[_selectedIndex]),
                  centerTitle: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                body: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),

      // 大屏幕布局 - 使用侧边导航栏和更宽的布局
      large: Scaffold(
        body: Row(
          children: [
            buildNavigationRail(),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('MongoDB比较同步工具'),
                  centerTitle: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                body: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveLayoutUtil.getResponsiveSpacing(
                      context,
                    ),
                  ),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
