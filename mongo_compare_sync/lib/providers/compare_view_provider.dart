import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/comparison_task.dart';

// 存储比较视图的状态
class CompareViewState {
  final String taskName;
  final List<BindingConfig> bindings;
  final MongoConnection? sourceConnection;
  final MongoConnection? targetConnection;

  CompareViewState({
    required this.taskName,
    required this.bindings,
    required this.sourceConnection,
    required this.targetConnection,
  });

  CompareViewState copyWith({
    String? taskName,
    List<BindingConfig>? bindings,
    MongoConnection? sourceConnection,
    MongoConnection? targetConnection,
    bool clearSourceConnection = false,
    bool clearTargetConnection = false,
  }) {
    return CompareViewState(
      taskName: taskName ?? this.taskName,
      bindings: bindings ?? this.bindings,
      sourceConnection: clearSourceConnection
          ? null
          : sourceConnection ?? this.sourceConnection,
      targetConnection: clearTargetConnection
          ? null
          : targetConnection ?? this.targetConnection,
    );
  }
}

class CompareViewNotifier extends StateNotifier<CompareViewState> {
  CompareViewNotifier()
    : super(
        CompareViewState(
          taskName: "",
          bindings: [],
          sourceConnection: null,
          targetConnection: null,
        ),
      );

  void setTaskName(String? taskName) {
    state = state.copyWith(taskName: taskName);
  }

  // 加载完整任务状态
  void loadTaskState({
    required String taskName,
    required List<BindingConfig> bindings,
    String? sourceConnectionId,
    String? targetConnectionId,
  }) {
    // 设置任务名称
    setTaskName(taskName);

    // 清空现有绑定并添加新绑定
    state = state.copyWith(bindings: []);
    for (final binding in bindings) {
      addBinding(binding);
    }
  }

  // 设置源连接
  void setSourceConnection(MongoConnection? connection) {
    state = state.copyWith(
      sourceConnection: connection,
      clearSourceConnection: connection == null,
    );
  }

  // 设置目标连接
  void setTargetConnection(MongoConnection? connection) {
    state = state.copyWith(
      targetConnection: connection,
      clearTargetConnection: connection == null,
    );
  }

  // 添加绑定
  void addBinding(BindingConfig binding) {
    if (!state.bindings.contains(binding)) {
      state = state.copyWith(bindings: [...state.bindings, binding]);
    }
  }

  // 移除绑定
  void removeBinding(BindingConfig binding) {
    state = state.copyWith(
      bindings: state.bindings.where((b) => b != binding).toList(),
    );
  }

  // 清除所有绑定
  void clearAllBindings() {
    state = state.copyWith(bindings: []);
  }
}

// 全局 provider
final compareViewProvider =
    StateNotifierProvider<CompareViewNotifier, CompareViewState>(
      (ref) => CompareViewNotifier(),
    );
