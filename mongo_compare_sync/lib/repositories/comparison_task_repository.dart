import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/comparison_task.dart';

class ComparisonTaskRepository {
  static const String _tasksFileName = 'comparison_tasks.json';

  // 获取任务文件路径
  Future<String> get _tasksFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_tasksFileName';
  }

  // 保存任务
  Future<void> saveTask(ComparisonTask task) async {
    final tasks = await getAllTasks();

    // 检查是否已存在同名任务，如果存在则更新
    final existingIndex = tasks.indexWhere((t) => t.name == task.name);
    if (existingIndex >= 0) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }

    await _saveTasks(tasks);
  }

  // 获取所有任务
  Future<List<ComparisonTask>> getAllTasks() async {
    try {
      final filePath = await _tasksFilePath;
      final file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);

      return jsonList.map((json) => ComparisonTask.fromJson(json)).toList();
    } catch (e) {
      print('Error loading comparison tasks: $e');
      return [];
    }
  }

  // 删除任务
  Future<void> deleteTask(String taskName) async {
    final tasks = await getAllTasks();
    tasks.removeWhere((task) => task.name == taskName);
    await _saveTasks(tasks);
  }

  // 保存所有任务到文件
  Future<void> _saveTasks(List<ComparisonTask> tasks) async {
    try {
      final filePath = await _tasksFilePath;
      final file = File(filePath);

      final jsonList = tasks.map((task) => task.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving comparison tasks: $e');
    }
  }
}
