import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  static LogService get instance => _instance;
  factory LogService() => _instance;

  late Logger _logger;
  bool _isEnabled = false;
  String? _logFilePath;

  LogService._internal() {
    _initLogger();
  }

  Future<void> _initLogger() async {
    // 检查是否启用日志记录
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('enableLogging') ?? false;

    // 创建日志目录
    if (_isEnabled) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 创建日志文件
      final now = DateTime.now();
      final fileName =
          'mongo_compare_sync_${now.year}-${now.month}-${now.day}.log';
      _logFilePath = '${logDir.path}/$fileName';

      // 配置日志输出
      _logger = Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: false,
          printEmojis: false,
          printTime: true,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          if (_logFilePath != null) FileOutput(file: File(_logFilePath!)),
        ]),
      );

      debug('日志服务初始化完成，日志文件路径: $_logFilePath');
    } else {
      // 如果未启用日志记录，则只输出到控制台
      _logger = Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: false,
          printTime: true,
        ),
      );
    }
  }

  // 更新日志记录状态
  Future<void> updateLoggingState(bool isEnabled) async {
    if (_isEnabled != isEnabled) {
      _isEnabled = isEnabled;
      await _initLogger();
    }
  }

  // 获取日志文件路径
  String? get logFilePath => _logFilePath;

  // 清除日志文件
  Future<void> clearLogs() async {
    if (_logFilePath != null) {
      final file = File(_logFilePath!);
      if (await file.exists()) {
        await file.delete();
        debug('日志文件已清除');
      }
    }
  }

  // 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDocDir.path}/logs');
    if (!await logDir.exists()) {
      return [];
    }

    final files = await logDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .toList();

    return files.map((entity) => entity as File).toList();
  }

  // 记录调试信息
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    final logMessage = _formatLogMessage(message, error, stackTrace);
    if (_isEnabled) {
      _logger.d(logMessage);
    } else if (kDebugMode) {
      _logger.d(logMessage);
    }
  }

  // 记录信息
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    final logMessage = _formatLogMessage(message, error, stackTrace);
    if (_isEnabled) {
      _logger.i(logMessage);
    } else if (kDebugMode) {
      _logger.i(logMessage);
    }
  }

  // 记录警告
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    final logMessage = _formatLogMessage(message, error, stackTrace);
    if (_isEnabled) {
      _logger.w(logMessage);
    } else if (kDebugMode) {
      _logger.w(logMessage);
    }
  }

  // 记录错误
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final logMessage = _formatLogMessage(message, error, stackTrace);
    if (_isEnabled) {
      _logger.e(logMessage);
    } else if (kDebugMode) {
      _logger.e(logMessage);
    }
  }

  // 记录严重错误
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    final logMessage = _formatLogMessage(message, error, stackTrace);
    if (_isEnabled) {
      _logger.f(logMessage);
    } else if (kDebugMode) {
      _logger.f(logMessage);
    }
  }

  // 格式化日志消息
  String _formatLogMessage(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (error != null) {
      message = '$message\nError: $error';
      if (stackTrace != null) {
        message = '$message\nStackTrace: $stackTrace';
      }
    }
    return message;
  }
}
