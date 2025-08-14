import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import '../models/sync_result.dart';
import '../widgets/diff_item.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/loading_indicator.dart';
import '../services/platform_service.dart';
import '../services/export_service.dart';
import '../providers/connection_provider.dart';

class ComparisonResultScreen extends ConsumerStatefulWidget {
  final List<DocumentDiff> results;
  final String sourceCollection;
  final String targetCollection;

  const ComparisonResultScreen({
    super.key,
    required this.results,
    required this.sourceCollection,
    required this.targetCollection,
  });

  @override
  ConsumerState<ComparisonResultScreen> createState() =>
      _ComparisonResultScreenState();
}

class _ComparisonResultScreenState
    extends ConsumerState<ComparisonResultScreen> {
  // 存储展开状态的Map
  final Map<String, bool> _expandedItems = {};
  // 过滤选项
  bool _showAdded = true;
  bool _showRemoved = true;
  bool _showModified = true;
  // 搜索关键字
  String _searchQuery = '';
  // 排序方式
  String _sortBy = 'path'; // 'path', 'type'

  // 同步方向
  bool _sourceToTarget = true;

  // 同步状态
  bool _isSyncing = false;
  SyncResult? _syncResult;

  @override
  Widget build(BuildContext context) {
    // 获取所有字段差异
    final List<FieldDiff> allFieldDiffs = _getAllFieldDiffs();

    // 过滤并排序结果
    final filteredDiffs = _filterDiffs(allFieldDiffs);

    // 获取平台服务和响应式布局工具
    final platformService = PlatformService.instance;
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);
    final spacing = ResponsiveLayoutUtil.getResponsiveSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: isSmallScreen
            ? const Text('比较结果')
            : Text(
                '比较结果: ${widget.sourceCollection} vs ${widget.targetCollection}',
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '导出结果',
            onPressed: _showExportDialog,
          ),
          _isSyncing
              ? IconButton(
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  tooltip: '正在同步...',
                  onPressed: null,
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: '同步数据',
                  onPressed: _showSyncDialog,
                ),
        ],
      ),
      body: ResponsiveLayout(
        // 小屏幕布局
        small: _buildSmallScreenLayout(
          allFieldDiffs,
          filteredDiffs,
          platformService,
          spacing,
        ),

        // 中等屏幕和大屏幕布局
        medium: _buildLargeScreenLayout(
          allFieldDiffs,
          filteredDiffs,
          platformService,
          spacing,
        ),

        // 大屏幕布局与中等屏幕相同
        large: null,
      ),
    );
  }

  // 小屏幕布局
  Widget _buildSmallScreenLayout(
    List<FieldDiff> allFieldDiffs,
    List<FieldDiff> filteredDiffs,
    PlatformService platformService,
    double spacing,
  ) {
    return Column(
      children: [
        // 源和目标集合信息
        Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '源集合: ${widget.sourceCollection}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '目标集合: ${widget.targetCollection}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // 过滤和搜索区域
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: _buildFilterBar(),
        ),

        // 结果统计信息
        _buildResultsSummary(allFieldDiffs),

        // 结果列表
        Expanded(
          child: _isSyncing
              ? const Center(
                  child: LoadingIndicator(message: '正在同步数据...', size: 40.0),
                )
              : filteredDiffs.isEmpty
              ? const Center(child: Text('没有符合条件的差异项'))
              : ListView.builder(
                  itemCount: filteredDiffs.length,
                  itemBuilder: (context, index) {
                    final diff = filteredDiffs[index];
                    return _buildDiffItemFromFieldDiff(diff);
                  },
                ),
        ),
      ],
    );
  }

  // 大屏幕布局
  Widget _buildLargeScreenLayout(
    List<FieldDiff> allFieldDiffs,
    List<FieldDiff> filteredDiffs,
    PlatformService platformService,
    double spacing,
  ) {
    return Column(
      children: [
        // 过滤和搜索区域
        Padding(padding: EdgeInsets.all(spacing), child: _buildFilterBar()),

        // 结果统计信息
        _buildResultsSummary(allFieldDiffs),

        // 结果列表
        Expanded(
          child: _isSyncing
              ? const Center(
                  child: LoadingIndicator(message: '正在同步数据...', size: 40.0),
                )
              : filteredDiffs.isEmpty
              ? const Center(child: Text('没有符合条件的差异项'))
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing),
                  child: Card(
                    elevation: platformService.getPlatformElevation(),
                    child: ListView.builder(
                      itemCount: filteredDiffs.length,
                      itemBuilder: (context, index) {
                        final diff = filteredDiffs[index];
                        return _buildDiffItemFromFieldDiff(diff);
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// 获取所有字段差异
  List<FieldDiff> _getAllFieldDiffs() {
    final List<FieldDiff> allDiffs = [];

    for (final docDiff in widget.results) {
      allDiffs.addAll(docDiff.fieldDiffList);
    }

    return allDiffs;
  }

  /// 构建过滤栏
  Widget _buildFilterBar() {
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);

    return Column(
      children: [
        // 搜索框
        TextField(
          decoration: InputDecoration(
            hintText: '搜索字段路径...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),

        // 过滤选项
        isSmallScreen
            ? Column(
                children: [
                  // 差异类型过滤
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('新增'),
                          selected: _showAdded,
                          onSelected: (value) {
                            setState(() {
                              _showAdded = value;
                            });
                          },
                          avatar: const Icon(Icons.add_circle, size: 18),
                          selectedColor: Colors.green.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('删除'),
                          selected: _showRemoved,
                          onSelected: (value) {
                            setState(() {
                              _showRemoved = value;
                            });
                          },
                          avatar: const Icon(Icons.remove_circle, size: 18),
                          selectedColor: Colors.red.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('修改'),
                          selected: _showModified,
                          onSelected: (value) {
                            setState(() {
                              _showModified = value;
                            });
                          },
                          avatar: const Icon(Icons.edit, size: 18),
                          selectedColor: Colors.amber.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 排序选项
                  DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'path', child: Text('按路径排序')),
                      DropdownMenuItem(value: 'type', child: Text('按类型排序')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  // 差异类型过滤
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('新增'),
                            selected: _showAdded,
                            onSelected: (value) {
                              setState(() {
                                _showAdded = value;
                              });
                            },
                            avatar: const Icon(Icons.add_circle, size: 18),
                            selectedColor: Colors.green.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('删除'),
                            selected: _showRemoved,
                            onSelected: (value) {
                              setState(() {
                                _showRemoved = value;
                              });
                            },
                            avatar: const Icon(Icons.remove_circle, size: 18),
                            selectedColor: Colors.red.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('修改'),
                            selected: _showModified,
                            onSelected: (value) {
                              setState(() {
                                _showModified = value;
                              });
                            },
                            avatar: const Icon(Icons.edit, size: 18),
                            selectedColor: Colors.amber.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 排序选项
                  DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'path', child: Text('按路径排序')),
                      DropdownMenuItem(value: 'type', child: Text('按类型排序')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ],
              ),
      ],
    );
  }

  /// 构建结果统计信息
  Widget _buildResultsSummary(List<FieldDiff> allDiffs) {
    final totalDiffs = allDiffs.length;
    final addedCount = allDiffs.where((diff) => diff.status == 'added').length;
    final removedCount = allDiffs
        .where((diff) => diff.status == 'removed')
        .length;
    final modifiedCount = allDiffs
        .where((diff) => diff.status == 'modified')
        .length;
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);

    return Container(
      padding: EdgeInsets.all(
        ResponsiveLayoutUtil.getResponsiveSpacing(context),
      ),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: isSmallScreen
          ? Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatItem('总差异', totalDiffs, Colors.blue),
                _buildStatItem('新增', addedCount, Colors.green),
                _buildStatItem('删除', removedCount, Colors.red),
                _buildStatItem('修改', modifiedCount, Colors.amber),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总差异', totalDiffs, Colors.blue),
                _buildStatItem('新增', addedCount, Colors.green),
                _buildStatItem('删除', removedCount, Colors.red),
                _buildStatItem('修改', modifiedCount, Colors.amber),
              ],
            ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

  /// 从FieldDiff构建DiffItem组件
  Widget _buildDiffItemFromFieldDiff(FieldDiff diff) {
    // 获取差异类型
    DiffType diffType;
    switch (diff.status) {
      case 'added':
        diffType = DiffType.added;
        break;
      case 'removed':
        diffType = DiffType.removed;
        break;
      case 'modified':
      default:
        diffType = DiffType.modified;
        break;
    }

    // 获取字段路径
    final fieldPath = diff.fieldPath;

    // 获取展开状态
    final isExpanded = _expandedItems[fieldPath] ?? false;

    return DiffItem(
      fieldPath: fieldPath,
      sourceValue: diff.sourceValue,
      targetValue: diff.targetValue,
      diffType: diffType,
      isExpanded: isExpanded,
      onToggleExpand: () {
        setState(() {
          _expandedItems[fieldPath] = !isExpanded;
        });
      },
    );
  }

  /// 过滤差异
  List<FieldDiff> _filterDiffs(List<FieldDiff> diffs) {
    // 应用过滤条件
    var filtered = diffs.where((diff) {
      // 按差异类型过滤
      if (diff.status == 'added' && !_showAdded) return false;
      if (diff.status == 'removed' && !_showRemoved) return false;
      if (diff.status == 'modified' && !_showModified) return false;

      // 按搜索关键字过滤
      if (_searchQuery.isNotEmpty) {
        return diff.fieldPath.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
      }

      return true;
    }).toList();

    // 应用排序
    if (_sortBy == 'path') {
      filtered.sort((a, b) => a.fieldPath.compareTo(b.fieldPath));
    } else if (_sortBy == 'type') {
      filtered.sort((a, b) {
        // 先按类型排序，再按路径排序
        final typeOrder = {'added': 0, 'removed': 1, 'modified': 2};
        final typeA = typeOrder[a.status] ?? 3;
        final typeB = typeOrder[b.status] ?? 3;
        if (typeA != typeB) {
          return typeA.compareTo(typeB);
        } else {
          return a.fieldPath.compareTo(b.fieldPath);
        }
      });
    }

    return filtered;
  }

  // 显示同步对话框
  void _showSyncDialog() {
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);
    final platformService = PlatformService.instance;
    final dialogWidth = isSmallScreen ? null : 500.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步数据'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('请选择同步方向:'),
                  const SizedBox(height: 8),

                  // 同步方向选择
                  Card(
                    elevation: platformService.getPlatformElevation() / 2,
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          title: Text(
                            '从源到目标',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${widget.sourceCollection} → ${widget.targetCollection}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: true,
                          groupValue: _sourceToTarget,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sourceToTarget = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<bool>(
                          title: Text(
                            '从目标到源',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${widget.targetCollection} → ${widget.sourceCollection}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: false,
                          groupValue: _sourceToTarget,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sourceToTarget = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('请选择要同步的差异类型:'),
                  const SizedBox(height: 8),

                  // 差异类型选择
                  Card(
                    elevation: platformService.getPlatformElevation() / 2,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('新增文档'),
                            ],
                          ),
                          value: _showAdded,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _showAdded = value;
                              });
                            }
                          },
                        ),
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('删除文档'),
                            ],
                          ),
                          value: _showRemoved,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _showRemoved = value;
                              });
                            }
                          },
                        ),
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              const Text('修改文档'),
                            ],
                          ),
                          value: _showModified,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _showModified = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _syncData();
            },
            child: const Text('同步'),
          ),
        ],
      ),
    );
  }

  // 执行同步操作
  Future<void> _syncData() async {
    // 获取要同步的差异类型
    final List<String> diffTypes = [];
    if (_showAdded) diffTypes.add('added');
    if (_showRemoved) diffTypes.add('removed');
    if (_showModified) diffTypes.add('modified');

    if (diffTypes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少选择一种差异类型进行同步')));
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncResult = null;
    });

    try {
      // 执行同步操作
      final mongoService = ref.read(mongoServiceProvider);
      final result = await mongoService.syncDocumentDiffs(
        widget.results,
        _sourceToTarget,
        diffTypes: diffTypes,
      );

      setState(() {
        _syncResult = result;
        _isSyncing = false;
      });

      // 显示同步结果
      _showSyncResultDialog(result);
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('同步失败: ${e.toString()}')));
    }
  }

  // 显示导出对话框
  void _showExportDialog() {
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);
    final platformService = PlatformService.instance;
    final dialogWidth = isSmallScreen ? null : 500.0;

    // 默认导出格式
    ExportFormat selectedFormat = ExportFormat.html;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出比较结果'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('请选择导出格式:'),
                  const SizedBox(height: 8),

                  // 导出格式选择
                  Card(
                    elevation: platformService.getPlatformElevation() / 2,
                    child: Column(
                      children: [
                        RadioListTile<ExportFormat>(
                          title: Row(
                            children: [
                              Icon(Icons.html, size: 20),
                              const SizedBox(width: 8),
                              const Text('HTML'),
                            ],
                          ),
                          subtitle: const Text('生成包含样式的HTML报告'),
                          value: ExportFormat.html,
                          groupValue: selectedFormat,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedFormat = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<ExportFormat>(
                          title: Row(
                            children: [
                              Icon(Icons.text_snippet, size: 20),
                              const SizedBox(width: 8),
                              const Text('Markdown'),
                            ],
                          ),
                          subtitle: const Text('生成Markdown格式的文本报告'),
                          value: ExportFormat.markdown,
                          groupValue: selectedFormat,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedFormat = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<ExportFormat>(
                          title: Row(
                            children: [
                              Icon(Icons.table_chart, size: 20),
                              const SizedBox(width: 8),
                              const Text('CSV'),
                            ],
                          ),
                          subtitle: const Text('生成可在电子表格中打开的CSV文件'),
                          value: ExportFormat.csv,
                          groupValue: selectedFormat,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedFormat = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<ExportFormat>(
                          title: Row(
                            children: [
                              Icon(Icons.data_object, size: 20),
                              const SizedBox(width: 8),
                              const Text('JSON'),
                            ],
                          ),
                          subtitle: const Text('生成结构化的JSON数据'),
                          value: ExportFormat.json,
                          groupValue: selectedFormat,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedFormat = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportResults(selectedFormat);
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  // 导出比较结果
  Future<void> _exportResults(ExportFormat format) async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在生成报告...'),
            ],
          ),
        ),
      );

      // 获取所有文档差异
      final List<DocumentDiff> results = widget.results;

      // 使用导出服务导出结果
      final exportService = ExportService.instance;
      final filePath = await exportService.exportComparisonResults(
        results: results,
        sourceCollection: widget.sourceCollection,
        targetCollection: widget.targetCollection,
        format: format,
      );

      // 关闭加载对话框
      Navigator.of(context).pop();

      if (filePath != null) {
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('报告已成功导出到: $filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: '确定', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 显示同步结果对话框
  void _showSyncResultDialog(SyncResult result) {
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);
    final platformService = PlatformService.instance;
    final dialogWidth = isSmallScreen ? null : 600.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasErrors ? Icons.warning_amber : Icons.check_circle,
              color: result.hasErrors ? Colors.amber : Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('同步结果'),
          ],
        ),
        content: Container(
          width: dialogWidth,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: platformService.getPlatformElevation() / 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '同步摘要',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(result.summary),
                      ],
                    ),
                  ),
                ),
                if (result.hasErrors) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: platformService.getPlatformElevation() / 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '错误详情',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: result.errors.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    result.errors[index],
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
          if (!result.hasErrors)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回到比较界面
              },
              child: const Text('完成'),
            ),
        ],
      ),
    );
  }
}
