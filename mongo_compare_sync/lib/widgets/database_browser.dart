import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../providers/connection_provider.dart';
import '../repositories/connection_repository.dart';

class DatabaseBrowser extends ConsumerStatefulWidget {
  final MongoConnection connection;
  final Function(String, String)? onCollectionSelected;
  final String? selectedDatabase;
  final String? selectedCollection;

  const DatabaseBrowser({
    super.key,
    required this.connection,
    this.onCollectionSelected,
    this.selectedDatabase,
    this.selectedCollection,
  });

  @override
  ConsumerState<DatabaseBrowser> createState() => _DatabaseBrowserState();
}

class _DatabaseBrowserState extends ConsumerState<DatabaseBrowser> {
  bool _isLoading = false;
  String? _error;
  List<String> _databases = [];
  Map<String, List<MongoCollection>> _collections = {};
  String? _selectedDatabase;
  String? _selectedCollection;

  @override
  void initState() {
    super.initState();
    _loadDatabases();

    // 如果有预选的数据库和集合，设置选中状态
    if (widget.selectedDatabase != null) {
      _selectedDatabase = widget.selectedDatabase;

      // 加载该数据库的集合
      _loadCollections(widget.selectedDatabase!);

      // 如果有预选的集合，设置选中状态
      if (widget.selectedCollection != null) {
        _selectedCollection = widget.selectedCollection;
      }
    }
  }

  @override
  void didUpdateWidget(DatabaseBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connection.id != widget.connection.id ||
        oldWidget.connection.isConnected != widget.connection.isConnected) {
      _loadDatabases();
    }
  }

  Future<void> _loadDatabases() async {
    if (!widget.connection.isConnected) {
      setState(() {
        _databases = [];
        _collections = {};
        _selectedDatabase = null;
        _selectedCollection = null;
        _error = '未连接到数据库';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(connectionRepositoryProvider);
      final databases = await repository.getDatabases(widget.connection.id);

      setState(() {
        _databases = databases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载数据库失败: ${e.toString()}';
      });
    }
  }

  Future<void> _loadCollections(String database) async {
    if (!widget.connection.isConnected) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mongoService = ref.read(mongoServiceProvider);
      final collections = await mongoService.getCollections(
        widget.connection.id,
        database,
      );

      setState(() {
        _collections[database] = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载集合失败: ${e.toString()}';
      });
    }
  }

  void _selectDatabase(String database) {
    setState(() {
      _selectedDatabase = database;
      _selectedCollection = null;
    });

    if (!_collections.containsKey(database) ||
        _collections[database]!.isEmpty) {
      _loadCollections(database);
    }
  }

  void _selectCollection(MongoCollection collection) {
    setState(() {
      _selectedCollection = collection.name;
    });

    if (widget.onCollectionSelected != null && _selectedDatabase != null) {
      widget.onCollectionSelected!(_selectedDatabase!, collection.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _databases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _databases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadDatabases, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_databases.isEmpty) {
      return const Center(
        child: Text(
          '没有可用的数据库',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Row(
      children: [
        // 数据库列表
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: _databases.length,
              itemBuilder: (context, index) {
                final database = _databases[index];
                final isSelected = database == _selectedDatabase;

                return ListTile(
                  title: Text(database),
                  selected: isSelected,
                  tileColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  leading: const Icon(Icons.storage),
                  onTap: () => _selectDatabase(database),
                );
              },
            ),
          ),
        ),

        // 集合列表
        Expanded(
          flex: 3,
          child: _selectedDatabase == null
              ? const Center(
                  child: Text(
                    '请选择一个数据库',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _collections[_selectedDatabase]?.isEmpty ?? true
              ? const Center(
                  child: Text(
                    '没有可用的集合',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _collections[_selectedDatabase]!.length,
                    itemBuilder: (context, index) {
                      final collection =
                          _collections[_selectedDatabase]![index];
                      final isSelected = collection.name == _selectedCollection;

                      return ListTile(
                        title: Text(collection.name),
                        selected: isSelected,
                        tileColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        leading: const Icon(Icons.table_chart),
                        onTap: () => _selectCollection(collection),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
