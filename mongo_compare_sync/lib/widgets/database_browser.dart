import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../providers/connection_provider.dart';
import '../repositories/connection_repository.dart';
import '../services/log_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/skeleton_loader.dart';

/// Represents a node in the database/collection tree view.
class TreeViewNode {
  final String id;
  final String name;
  final bool isDatabase;
  final String? parentDatabase; // For collections, indicates parent database
  final List<TreeViewNode> children;
  final bool hasError; // Indicates if there was an error loading children
  final bool isLoading; // Indicates if children are currently loading

  TreeViewNode({
    required this.id,
    required this.name,
    required this.isDatabase,
    this.parentDatabase,
    this.children = const [],
    this.hasError = false,
    this.isLoading = false,
  });

  TreeViewNode copyWith({
    String? id,
    String? name,
    bool? isDatabase,
    String? parentDatabase,
    List<TreeViewNode>? children,
    bool? hasError,
    bool? isLoading,
  }) {
    return TreeViewNode(
      id: id ?? this.id,
      name: name ?? this.name,
      isDatabase: isDatabase ?? this.isDatabase,
      parentDatabase: parentDatabase ?? this.parentDatabase,
      children: children ?? this.children,
      hasError: hasError ?? this.hasError,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DatabaseTreeView extends ConsumerStatefulWidget {
  final MongoConnection? connection;
  final Function(String databaseName)? onDatabaseSelected;
  final Function(String databaseName, String collectionName)?
  onCollectionSelected;
  final String? selectedDatabase;
  final String? selectedCollection;
  final bool isSource; // To differentiate source/target for UI

  const DatabaseTreeView({
    super.key,
    required this.connection,
    this.onDatabaseSelected,
    this.onCollectionSelected,
    this.selectedDatabase,
    this.selectedCollection,
    required this.isSource,
  });

  @override
  ConsumerState<DatabaseTreeView> createState() => _DatabaseTreeViewState();
}

class _DatabaseTreeViewState extends ConsumerState<DatabaseTreeView> {
  List<TreeViewNode> _databaseNodes = [];
  String? _error;
  bool _isLoadingDatabases = false;

  @override
  void didUpdateWidget(covariant DatabaseTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connection?.id != oldWidget.connection?.id) {
      _loadDatabases();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    if (widget.connection == null) {
      setState(() {
        _databaseNodes = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoadingDatabases = true;
      _error = null;
      _databaseNodes = []; // Clear previous databases
    });

    try {
      final repository = ref.read(connectionRepositoryProvider);
      final databases = await repository.getDatabases(widget.connection!.id);
      if (mounted) {
        setState(() {
          _databaseNodes = databases
              .map(
                (dbName) => TreeViewNode(
                  id: dbName,
                  name: dbName,
                  isDatabase: true,
                  isLoading: false, // Initially not loading collections
                  hasError: false,
                ),
              )
              .toList();
          _isLoadingDatabases = false;
        });
      }
    } catch (e, stackTrace) {
      LogService.instance.error('加载数据库列表失败: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = '加载数据库失败: ${e.toString()}';
          _isLoadingDatabases = false;
        });
      }
    }
  }

  Future<void> _loadCollections(TreeViewNode databaseNode) async {
    if (widget.connection == null || !databaseNode.isDatabase) return;

    final index = _databaseNodes.indexOf(databaseNode);
    if (index == -1) return;

    setState(() {
      _databaseNodes[index] = databaseNode.copyWith(
        isLoading: true,
        hasError: false,
        children: [],
      );
    });

    try {
      final repository = ref.read(connectionRepositoryProvider);
      final collections = await repository.getCollections(
        widget.connection!.id,
        databaseNode.name,
      );
      if (mounted) {
        setState(() {
          _databaseNodes[index] = databaseNode.copyWith(
            isLoading: false,
            children: collections
                .map(
                  (coll) => TreeViewNode(
                    id: '${databaseNode.name}.${coll.name}',
                    name: coll.name,
                    isDatabase: false,
                    parentDatabase: databaseNode.name,
                  ),
                )
                .toList(),
          );
        });
      }
    } catch (e, stackTrace) {
      LogService.instance.error('加载集合列表失败: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _databaseNodes[index] = databaseNode.copyWith(
            isLoading: false,
            hasError: true,
            children: [],
          );
          _error = '加载 ${databaseNode.name} 集合失败: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.connection == null) {
      return const Center(child: Text('请选择连接'));
    }

    if (_isLoadingDatabases) {
      return const Center(
        child: LoadingIndicator(message: '加载数据库...', size: 24),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadDatabases, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_databaseNodes.isEmpty) {
      return const Center(child: Text('没有发现数据库'));
    }

    return ListView.builder(
      itemCount: _databaseNodes.length,
      itemBuilder: (context, index) {
        final node = _databaseNodes[index];
        return _buildNode(node);
      },
    );
  }

  Widget _buildNode(TreeViewNode node) {
    if (node.isDatabase) {
      final isSelected =
          widget.selectedDatabase == node.name &&
          widget.selectedCollection == null;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        color: isSelected
            ? (widget.isSource
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer)
            : null,
        child: ExpansionTile(
          key: PageStorageKey(node.id),
          leading: const Icon(Icons.folder_open),
          title: Text(node.name),
          trailing: node.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (node.hasError
                    ? Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      )
                    : null),
          onExpansionChanged: (expanded) {
            if (expanded &&
                node.children.isEmpty &&
                !node.isLoading &&
                !node.hasError) {
              _loadCollections(node);
            }
            if (expanded) {
              widget.onDatabaseSelected?.call(node.name);
            }
          },
          children: [
            if (node.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LoadingIndicator(message: '加载集合...', size: 20),
              ),
            if (node.hasError)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '加载集合失败: ${node.name}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!node.isLoading && !node.hasError && node.children.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('没有发现集合'),
              ),
            ...node.children.map((childNode) => _buildNode(childNode)),
          ],
        ),
      );
    } else {
      final isSelected =
          widget.selectedDatabase == node.parentDatabase &&
          widget.selectedCollection == node.name;
      return Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          color: isSelected
              ? (widget.isSource
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer)
              : null,
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(node.name),
            onTap: () {
              widget.onCollectionSelected?.call(
                node.parentDatabase!,
                node.name,
              );
            },
          ),
        ),
      );
    }
  }
}
