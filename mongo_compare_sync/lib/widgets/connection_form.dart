import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/connection_provider.dart';
import 'package:uuid/uuid.dart';

class ConnectionForm extends ConsumerStatefulWidget {
  final MongoConnection? initialConnection;

  const ConnectionForm({super.key, this.initialConnection});

  @override
  ConsumerState<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends ConsumerState<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _databaseController;
  bool _isAuthEnabled = false;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final connection = widget.initialConnection;
    _nameController = TextEditingController(text: connection?.name ?? '');
    _hostController = TextEditingController(
      text: connection?.host ?? 'localhost',
    );
    _portController = TextEditingController(
      text: connection?.port.toString() ?? '27017',
    );
    _usernameController = TextEditingController(
      text: connection?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: connection?.password ?? '',
    );
    _databaseController = TextEditingController(
      text: connection?.authSource ?? '',
    );
    _isAuthEnabled = connection?.username?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final connection = _buildConnection();
    final notifier = ref.read(connectionsProvider.notifier);

    try {
      final isConnected = await notifier.testConnection(connection);
      setState(() {
        _isTesting = false;
        _testResult = isConnected ? '连接成功！' : '连接失败，请检查连接信息。';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = '连接错误: ${e.toString()}';
      });
    }
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final connection = _buildConnection();
      final notifier = ref.read(connectionsProvider.notifier);

      // 显示保存中的加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('保存中...'),
            ],
          ),
        ),
      );

      // 保存连接
      if (widget.initialConnection != null) {
        await notifier.updateConnection(connection);
      } else {
        await notifier.addConnection(connection);
      }

      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 延迟一下再返回上一页，确保状态已更新
      await Future.delayed(const Duration(milliseconds: 300));

      // 返回上一页
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${e.toString()}')));
      }
    }
  }

  MongoConnection _buildConnection() {
    final connection = widget.initialConnection;
    return MongoConnection(
      id: connection?.id ?? const Uuid().v4(),
      name: _nameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 27017,
      username: _isAuthEnabled ? _usernameController.text : null,
      password: _isAuthEnabled ? _passwordController.text : null,
      authSource: _databaseController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '连接名称',
                hintText: '输入一个易于识别的名称',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入连接名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: '主机地址',
                hintText: '例如: localhost 或 192.168.1.100',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入主机地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '默认: 27017',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端口号';
                }
                final port = int.tryParse(value);
                if (port == null || port <= 0 || port > 65535) {
                  return '请输入有效的端口号 (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用身份验证'),
              value: _isAuthEnabled,
              onChanged: (value) {
                setState(() {
                  _isAuthEnabled = value;
                });
              },
            ),
            if (_isAuthEnabled) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (_isAuthEnabled && (value == null || value.isEmpty)) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (_isAuthEnabled && (value == null || value.isEmpty)) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _databaseController,
              decoration: const InputDecoration(
                labelText: '数据库名称 (可选)',
                hintText: '留空以列出所有数据库',
                prefixIcon: Icon(Icons.storage),
              ),
            ),
            const SizedBox(height: 24),
            if (_testResult != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testResult!.contains('成功')
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('测试连接'),
                ),
                ElevatedButton.icon(
                  onPressed: _saveConnection,
                  icon: const Icon(Icons.save),
                  label: Text(widget.initialConnection != null ? '更新' : '保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
