import 'dart:io';
import 'package:flutter/material.dart';
import '../services/log_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<File> _logFiles = [];
  String? _selectedLogContent;
  String? _selectedLogPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logFiles = await LogService.instance.getLogFiles();
      setState(() {
        _logFiles = logFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日志文件失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewLogFile(File file) async {
    setState(() {
      _isLoading = true;
      _selectedLogPath = file.path;
    });

    try {
      final content = await file.readAsString();
      setState(() {
        _selectedLogContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedLogContent = '无法读取日志文件: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
            tooltip: '刷新日志列表',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logFiles.isEmpty
          ? const Center(child: Text('没有找到日志文件'))
          : Row(
              children: [
                // 左侧日志文件列表
                Expanded(
                  flex: 1,
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _logFiles.length,
                      itemBuilder: (context, index) {
                        final file = _logFiles[index];
                        final fileName = file.path.split('/').last;
                        final isSelected = file.path == _selectedLogPath;

                        return ListTile(
                          title: Text(fileName),
                          subtitle: Text(
                            '大小: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                          ),
                          selected: isSelected,
                          tileColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          onTap: () => _viewLogFile(file),
                        );
                      },
                    ),
                  ),
                ),

                // 右侧日志内容
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: _selectedLogContent == null
                        ? const Center(child: Text('请选择一个日志文件查看'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: SelectableText(
                              _selectedLogContent!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
