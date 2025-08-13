import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import '../models/sync_result.dart';
import '../widgets/diff_item.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '比较结果: ${widget.sourceCollection} vs ${widget.targetCollection}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '导出结果',
            onPressed: () {
              // TODO: 实现导出功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('导出功能尚未实现')));
            },
          ),
          _isSyncing
              ? const IconButton(
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
      body: Column(
        children: [
          // 过滤和搜索区域
          _buildFilterBar(),

          // 结果统计信息
          _buildResultsSummary(allFieldDiffs),

          // 结果列表
          Expanded(
            child: filteredDiffs.isEmpty
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
      ),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // 搜索框
          TextField(
            decoration: InputDecoration(
              hintText: '搜索字段路径...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          Row(
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
      ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步数据'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('请选择同步方向:'),
                const SizedBox(height: 8),

                // 同步方向选择
                RadioListTile<bool>(
                  title: Text(
                    '从源到目标 (${widget.sourceCollection} → ${widget.targetCollection})',
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
                    '从目标到源 (${widget.targetCollection} → ${widget.sourceCollection})',
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

                const SizedBox(height: 16),
                const Text('请选择要同步的差异类型:'),
                const SizedBox(height: 8),

                // 差异类型选择
                CheckboxListTile(
                  title: const Text('新增文档'),
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
                  title: const Text('删除文档'),
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
                  title: const Text('修改文档'),
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
          TextButton(
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

  // 显示同步结果对话框
  void _showSyncResultDialog(SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summary),
            if (result.hasErrors) ...[
              const SizedBox(height: 16),
              const Text(
                '错误详情:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: result.errors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        result.errors[index],
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
