import 'package:hive/hive.dart';
import 'connection.dart';
import 'compare_rule.dart';
import 'app_settings.dart';

// 这个文件用于注册所有的Hive适配器
void registerHiveAdapters() {
  // 注册枚举适配器
  Hive.registerAdapter(RuleTypeAdapter());
  Hive.registerAdapter(ExportFormatAdapter());

  // 注册模型适配器
  // 注意：这些适配器会在代码生成后自动创建
  // 我们只需要在应用启动时调用这个函数
}

// 为ExportFormat枚举创建适配器
class ExportFormatAdapter extends TypeAdapter<ExportFormat> {
  @override
  final int typeId = 5;

  @override
  ExportFormat read(BinaryReader reader) {
    return ExportFormat.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ExportFormat obj) {
    writer.writeByte(obj.index);
  }
}

// 为枚举创建适配器
class RuleTypeAdapter extends TypeAdapter<RuleType> {
  @override
  final int typeId = 3;

  @override
  RuleType read(BinaryReader reader) {
    return RuleType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, RuleType obj) {
    writer.writeByte(obj.index);
  }
}
