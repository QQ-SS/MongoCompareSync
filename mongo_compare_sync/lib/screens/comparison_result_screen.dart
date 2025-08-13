import 'package:flutter/material.dart';
import '../models/document.dart';
import '../widgets/diff_item.dart';

class ComparisonResultScreen extends StatefulWidget {
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
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
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
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '同步数据',
            onPressed: () {
              // TODO: 实现同步功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('同步功能尚未实现')));
            },
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
}
