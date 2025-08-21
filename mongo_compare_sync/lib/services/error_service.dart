import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'log_service.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  static ErrorService get instance => _instance;
  factory ErrorService() => _instance;

  final LogService _logService = LogService();

  // 全局错误处理函数
  late Function(BuildContext, String, String?) _errorHandler;

  ErrorService._internal() {
    // 默认错误处理函数
    _errorHandler = _defaultErrorHandler;
  }

  // 设置自定义错误处理函数
  void setErrorHandler(Function(BuildContext, String, String?) handler) {
    _errorHandler = handler;
  }

  // 默认错误处理函数
  void _defaultErrorHandler(
    BuildContext context,
    String message,
    String? details,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: details != null
            ? SnackBarAction(
                label: '详情',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('错误详情'),
                      content: SingleChildScrollView(child: Text(details)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  // 初始化全局错误捕获
  void initErrorCapture() {
    // 捕获Flutter框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      _logService.error('Flutter框架错误', details.exception, details.stack);

      if (kReleaseMode) {
        // 在发布模式下，将错误报告给服务器
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.empty,
        );
      } else {
        // 在调试模式下，将错误打印到控制台
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 捕获未处理的异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      _logService.error('未处理的异步错误', error, stack);
      return true;
    };
  }

  // 处理MongoDB连接错误
  void handleMongoConnectionError(
    BuildContext context,
    dynamic error, {
    String? connectionName,
  }) {
    final message =
        '连接MongoDB数据库失败${connectionName != null ? " ($connectionName)" : ""}';
    final details = error.toString();

    _logService.error(message, error);
    _errorHandler(context, message, details);
  }

  // 处理MongoDB查询错误
  void handleMongoQueryError(
    BuildContext context,
    dynamic error, {
    String? query,
  }) {
    final message = '执行MongoDB查询失败';
    final details = query != null
        ? '查询: $query\n错误: ${error.toString()}'
        : error.toString();

    _logService.error(message, error);
    _errorHandler(context, message, details);
  }

  // 处理MongoDB同步错误
  void handleMongoSyncError(
    BuildContext context,
    dynamic error, {
    String? operation,
  }) {
    final message =
        '执行MongoDB同步操作失败${operation != null ? " ($operation)" : ""}';
    final details = error.toString();

    _logService.error(message, error);
    _errorHandler(context, message, details);
  }

  // 处理文件操作错误
  void handleFileError(
    BuildContext context,
    dynamic error, {
    String? filePath,
    String? operation,
  }) {
    final message = '文件操作失败${operation != null ? " ($operation)" : ""}';
    final details = filePath != null
        ? '文件: $filePath\n错误: ${error.toString()}'
        : error.toString();

    _logService.error(message, error);
    _errorHandler(context, message, details);
  }

  // 处理通用错误
  void handleError(
    BuildContext context,
    String message,
    dynamic error, {
    String? details,
  }) {
    final errorDetails = details ?? error.toString();

    _logService.error(message, error);
    _errorHandler(context, message, errorDetails);
  }

  // 处理致命错误
  void handleFatalError(BuildContext context, String message, dynamic error) {
    _logService.fatal(message, error);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('严重错误'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text('应用遇到了严重错误，需要重新启动。'),
              if (error != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '错误详情:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 在实际应用中，这里可以重启应用或退出应用
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
