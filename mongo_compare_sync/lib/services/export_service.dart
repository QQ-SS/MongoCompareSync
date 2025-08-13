import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import 'log_service.dart';
import 'platform_service.dart';

/// 导出格式枚举
enum ExportFormat { csv, html, json, markdown }

/// 导出服务，用于将比较结果导出为各种格式
class ExportService {
  static final ExportService _instance = ExportService._internal();
  static ExportService get instance => _instance;
  factory ExportService() => _instance;

  final LogService _logService = LogService.instance;
  final PlatformService _platformService = PlatformService.instance;

  ExportService._internal();

  /// 导出比较结果
  Future<String?> exportComparisonResults({
    required List<DocumentDiff> results,
    required String sourceCollection,
    required String targetCollection,
    ExportFormat format = ExportFormat.html,
    String? customPath,
  }) async {
    try {
      _logService.info('开始导出比较结果，格式: ${format.name}');

      // 生成报告内容
      String content;
      String extension;

      switch (format) {
        case ExportFormat.csv:
          content = _generateCsvReport(
            results,
            sourceCollection,
            targetCollection,
          );
          extension = 'csv';
          break;
        case ExportFormat.html:
          content = _generateHtmlReport(
            results,
            sourceCollection,
            targetCollection,
          );
          extension = 'html';
          break;
        case ExportFormat.json:
          content = _generateJsonReport(
            results,
            sourceCollection,
            targetCollection,
          );
          extension = 'json';
          break;
        case ExportFormat.markdown:
          content = _generateMarkdownReport(
            results,
            sourceCollection,
            targetCollection,
          );
          extension = 'md';
          break;
      }

      // 确定保存路径
      String? filePath;
      if (customPath != null) {
        filePath = customPath;
      } else {
        // 使用文件选择器让用户选择保存位置
        filePath = await FilePicker.platform.saveFile(
          dialogTitle: '保存比较结果报告',
          fileName: _generateDefaultFileName(
            sourceCollection,
            targetCollection,
            extension,
          ),
          allowedExtensions: [extension],
          type: FileType.custom,
        );
      }

      if (filePath == null) {
        _logService.info('用户取消了导出操作');
        return null;
      }

      // 确保文件路径有正确的扩展名
      if (!filePath.toLowerCase().endsWith('.$extension')) {
        filePath = '$filePath.$extension';
      }

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(content);

      _logService.info('比较结果已成功导出到: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      _logService.error('导出比较结果失败', e, stackTrace);
      rethrow;
    }
  }

  /// 生成默认的文件名
  String _generateDefaultFileName(
    String sourceCollection,
    String targetCollection,
    String extension,
  ) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = formatter.format(now);

    // 清理集合名称，移除特殊字符
    final cleanSourceName = sourceCollection.replaceAll(
      RegExp(r'[^\w\.]'),
      '_',
    );
    final cleanTargetName = targetCollection.replaceAll(
      RegExp(r'[^\w\.]'),
      '_',
    );

    return 'mongo_compare_${cleanSourceName}_vs_${cleanTargetName}_$timestamp.$extension';
  }

  /// 生成CSV格式的报告
  String _generateCsvReport(
    List<DocumentDiff> results,
    String sourceCollection,
    String targetCollection,
  ) {
    final buffer = StringBuffer();

    // 添加标题行
    buffer.writeln('状态,文档ID,字段路径,源值,目标值');

    // 添加数据行
    for (var diff in results) {
      final status = diff.status;
      final id = diff.sourceDocument.id;

      if (diff.diffType == DocumentDiffType.modified &&
          diff.fieldDiffs != null) {
        // 对于修改的文档，添加每个修改的字段
        for (var fieldDiff in diff.fieldDiffs!.entries) {
          final fieldPath = fieldDiff.key;
          final fieldData = fieldDiff.value;
          final sourceValue = _formatCsvValue(fieldData['source']);
          final targetValue = _formatCsvValue(fieldData['target']);

          buffer.writeln('$status,$id,$fieldPath,$sourceValue,$targetValue');
        }
      } else {
        // 对于新增或删除的文档，添加整个文档
        buffer.writeln(
          '$status,$id,整个文档,${diff.diffType == DocumentDiffType.added ? "存在" : "不存在"},${diff.diffType == DocumentDiffType.removed ? "存在" : "不存在"}',
        );
      }
    }

    return buffer.toString();
  }

  /// 格式化CSV值，处理逗号和换行符
  String _formatCsvValue(dynamic value) {
    if (value == null) return '';

    String strValue = value.toString();
    // 如果值包含逗号、引号或换行符，则用引号包围并将引号转义
    if (strValue.contains(',') ||
        strValue.contains('"') ||
        strValue.contains('\n')) {
      strValue = '"${strValue.replaceAll('"', '""')}"';
    }
    return strValue;
  }

  /// 生成HTML格式的报告
  String _generateHtmlReport(
    List<DocumentDiff> results,
    String sourceCollection,
    String targetCollection,
  ) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timestamp = formatter.format(now);

    final buffer = StringBuffer();

    // HTML头部
    buffer.writeln('''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MongoDB比较报告: $sourceCollection vs $targetCollection</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    h1, h2, h3 {
      color: #2196F3;
    }
    .metadata {
      background-color: #f5f5f5;
      padding: 15px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .summary {
      display: flex;
      justify-content: space-around;
      margin: 20px 0;
      text-align: center;
    }
    .summary-item {
      padding: 10px;
      border-radius: 5px;
    }
    .total { background-color: #E3F2FD; }
    .added { background-color: #E8F5E9; }
    .removed { background-color: #FFEBEE; }
    .modified { background-color: #FFF8E1; }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    th, td {
      padding: 8px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
    tr:hover {
      background-color: #f5f5f5;
    }
    .status-added { color: #4CAF50; }
    .status-removed { color: #F44336; }
    .status-modified { color: #FF9800; }
    
    .diff-details {
      margin-top: 5px;
      padding: 8px;
      background-color: #f9f9f9;
      border-left: 3px solid #ddd;
      font-family: monospace;
      white-space: pre-wrap;
      overflow-x: auto;
    }
    
    .footer {
      margin-top: 30px;
      text-align: center;
      font-size: 0.8em;
      color: #666;
    }
  </style>
</head>
<body>
  <h1>MongoDB比较报告</h1>
  
  <div class="metadata">
    <p><strong>源集合:</strong> $sourceCollection</p>
    <p><strong>目标集合:</strong> $targetCollection</p>
    <p><strong>比较时间:</strong> $timestamp</p>
  </div>
''');

    // 添加摘要信息
    final totalDiffs = results.length;
    final addedCount = results.where((diff) => diff.status == 'added').length;
    final removedCount = results
        .where((diff) => diff.status == 'removed')
        .length;
    final modifiedCount = results
        .where((diff) => diff.status == 'modified')
        .length;

    buffer.writeln('''
  <div class="summary">
    <div class="summary-item total">
      <h3>总差异</h3>
      <p>$totalDiffs</p>
    </div>
    <div class="summary-item added">
      <h3>新增</h3>
      <p>$addedCount</p>
    </div>
    <div class="summary-item removed">
      <h3>删除</h3>
      <p>$removedCount</p>
    </div>
    <div class="summary-item modified">
      <h3>修改</h3>
      <p>$modifiedCount</p>
    </div>
  </div>
''');

    // 添加详细差异信息
    if (addedCount > 0) {
      buffer.writeln('<h2>新增文档</h2>');
      buffer.writeln('<table>');
      buffer.writeln('<tr><th>文档ID</th><th>详情</th></tr>');

      for (var diff in results.where((d) => d.status == 'added')) {
        buffer.writeln('<tr>');
        buffer.writeln('<td>${diff.sourceDocument.id}</td>');
        buffer.writeln('<td>');
        buffer.writeln('<div class="diff-details">');
        buffer.writeln(_formatJsonForHtml(diff.sourceDocument.data));
        buffer.writeln('</div>');
        buffer.writeln('</td>');
        buffer.writeln('</tr>');
      }

      buffer.writeln('</table>');
    }

    if (removedCount > 0) {
      buffer.writeln('<h2>删除文档</h2>');
      buffer.writeln('<table>');
      buffer.writeln('<tr><th>文档ID</th><th>详情</th></tr>');

      for (var diff in results.where((d) => d.status == 'removed')) {
        buffer.writeln('<tr>');
        buffer.writeln('<td>${diff.sourceDocument.id}</td>');
        buffer.writeln('<td>');
        buffer.writeln('<div class="diff-details">');
        buffer.writeln(_formatJsonForHtml(diff.targetDocument?.data ?? {}));
        buffer.writeln('</div>');
        buffer.writeln('</td>');
        buffer.writeln('</tr>');
      }

      buffer.writeln('</table>');
    }

    if (modifiedCount > 0) {
      buffer.writeln('<h2>修改文档</h2>');
      buffer.writeln('<table>');
      buffer.writeln(
        '<tr><th>文档ID</th><th>字段路径</th><th>源值</th><th>目标值</th></tr>',
      );

      for (var diff in results.where((d) => d.status == 'modified')) {
        if (diff.fieldDiffs == null) continue;
        for (var fieldDiff in diff.fieldDiffs!.entries) {
          final fieldPath = fieldDiff.key;
          final fieldData = fieldDiff.value;

          buffer.writeln('<tr>');
          buffer.writeln('<td>${diff.sourceDocument.id}</td>');
          buffer.writeln('<td>$fieldPath</td>');
          buffer.writeln(
            '<td>${_formatValueForHtml(fieldData['source'])}</td>',
          );
          buffer.writeln(
            '<td>${_formatValueForHtml(fieldData['target'])}</td>',
          );
          buffer.writeln('</tr>');
        }
      }

      buffer.writeln('</table>');
    }

    // HTML尾部
    buffer.writeln('''
  <div class="footer">
    <p>由MongoDB比较同步工具生成</p>
  </div>
</body>
</html>
''');

    return buffer.toString();
  }

  /// 格式化JSON以在HTML中显示
  String _formatJsonForHtml(Map<String, dynamic> json) {
    // 简单格式化，实际应用中可能需要更复杂的格式化
    return json
        .toString()
        .replaceAll('{', '{\n  ')
        .replaceAll('}', '\n}')
        .replaceAll(', ', ',\n  ');
  }

  /// 格式化值以在HTML中显示
  String _formatValueForHtml(dynamic value) {
    if (value == null) return '<em>null</em>';

    if (value is Map) {
      return '<div class="diff-details">${_formatJsonForHtml(value as Map<String, dynamic>)}</div>';
    } else if (value is List) {
      return '<div class="diff-details">$value</div>';
    } else {
      return value.toString().replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    }
  }

  /// 生成JSON格式的报告
  String _generateJsonReport(
    List<DocumentDiff> results,
    String sourceCollection,
    String targetCollection,
  ) {
    final now = DateTime.now();
    final timestamp = now.toIso8601String();

    final Map<String, dynamic> report = {
      'metadata': {
        'sourceCollection': sourceCollection,
        'targetCollection': targetCollection,
        'timestamp': timestamp,
        'platform': _platformService.isMacOS ? 'macOS' : 'Windows',
      },
      'summary': {
        'totalDiffs': results.length,
        'added': results.where((diff) => diff.status == 'added').length,
        'removed': results.where((diff) => diff.status == 'removed').length,
        'modified': results.where((diff) => diff.status == 'modified').length,
      },
      'diffs': results.map((diff) {
        final Map<String, dynamic> diffMap = {
          'id': diff.sourceDocument.id,
          'status': diff.status,
        };

        if (diff.diffType == DocumentDiffType.added) {
          diffMap['document'] = diff.sourceDocument.data;
        } else if (diff.diffType == DocumentDiffType.removed) {
          diffMap['document'] = diff.targetDocument?.data;
        } else if (diff.diffType == DocumentDiffType.modified) {
          diffMap['fieldDiffs'] = diff.fieldDiffs;
        }

        return diffMap;
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }

  /// 生成Markdown格式的报告
  String _generateMarkdownReport(
    List<DocumentDiff> results,
    String sourceCollection,
    String targetCollection,
  ) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timestamp = formatter.format(now);

    final buffer = StringBuffer();

    // 添加标题和元数据
    buffer.writeln('# MongoDB比较报告');
    buffer.writeln();
    buffer.writeln('## 元数据');
    buffer.writeln();
    buffer.writeln('- **源集合:** $sourceCollection');
    buffer.writeln('- **目标集合:** $targetCollection');
    buffer.writeln('- **比较时间:** $timestamp');
    buffer.writeln();

    // 添加摘要信息
    final totalDiffs = results.length;
    final addedCount = results.where((diff) => diff.status == 'added').length;
    final removedCount = results
        .where((diff) => diff.status == 'removed')
        .length;
    final modifiedCount = results
        .where((diff) => diff.status == 'modified')
        .length;

    buffer.writeln('## 摘要');
    buffer.writeln();
    buffer.writeln('- **总差异:** $totalDiffs');
    buffer.writeln('- **新增:** $addedCount');
    buffer.writeln('- **删除:** $removedCount');
    buffer.writeln('- **修改:** $modifiedCount');
    buffer.writeln();

    // 添加详细差异信息
    if (addedCount > 0) {
      buffer.writeln('## 新增文档');
      buffer.writeln();

      for (var diff in results.where((d) => d.status == 'added')) {
        buffer.writeln('### 文档ID: ${diff.sourceDocument.id}');
        buffer.writeln();
        buffer.writeln('```json');
        buffer.writeln(
          const JsonEncoder.withIndent('  ').convert(diff.sourceDocument.data),
        );
        buffer.writeln('```');
        buffer.writeln();
      }
    }

    if (removedCount > 0) {
      buffer.writeln('## 删除文档');
      buffer.writeln();

      for (var diff in results.where((d) => d.status == 'removed')) {
        buffer.writeln('### 文档ID: ${diff.sourceDocument.id}');
        buffer.writeln();
        buffer.writeln('```json');
        buffer.writeln(
          const JsonEncoder.withIndent(
            '  ',
          ).convert(diff.targetDocument?.data ?? {}),
        );
        buffer.writeln('```');
        buffer.writeln();
      }
    }

    if (modifiedCount > 0) {
      buffer.writeln('## 修改文档');
      buffer.writeln();

      for (var diff in results.where((d) => d.status == 'modified')) {
        buffer.writeln('### 文档ID: ${diff.sourceDocument.id}');
        buffer.writeln();
        buffer.writeln('| 字段路径 | 源值 | 目标值 |');
        buffer.writeln('|---------|------|--------|');

        if (diff.fieldDiffs == null) continue;
        for (var fieldDiff in diff.fieldDiffs!.entries) {
          final fieldPath = fieldDiff.key;
          final fieldData = fieldDiff.value;
          final sourceValue = _formatValueForMarkdown(fieldData['source']);
          final targetValue = _formatValueForMarkdown(fieldData['target']);

          buffer.writeln('| $fieldPath | $sourceValue | $targetValue |');
        }

        buffer.writeln();
      }
    }

    // 添加页脚
    buffer.writeln('---');
    buffer.writeln('*由MongoDB比较同步工具生成*');

    return buffer.toString();
  }

  /// 格式化值以在Markdown中显示
  String _formatValueForMarkdown(dynamic value) {
    if (value == null) return '*null*';

    if (value is Map || value is List) {
      String jsonStr = const JsonEncoder.withIndent('  ').convert(value);
      // 在Markdown表格中，需要转义竖线
      jsonStr = jsonStr.replaceAll('|', '\\|');
      // 为了在表格中显示得更好，将多行内容压缩为单行
      return jsonStr.replaceAll('\n', ' ');
    } else {
      return value.toString().replaceAll('|', '\\|');
    }
  }
}
