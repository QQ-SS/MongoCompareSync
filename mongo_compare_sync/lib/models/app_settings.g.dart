// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      id: fields[0] as String,
      themeModeIndex: fields[1] as int,
      locale: fields[2] as String,
      pageSize: fields[3] as int,
      showObjectIds: fields[4] as bool,
      defaultRuleId: fields[5] as String?,
      caseSensitiveComparison: fields[6] as bool,
      defaultExportFormatIndex: fields[7] as int,
      confirmBeforeSync: fields[8] as bool,
      enableLogging: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.themeModeIndex)
      ..writeByte(2)
      ..write(obj.locale)
      ..writeByte(3)
      ..write(obj.pageSize)
      ..writeByte(4)
      ..write(obj.showObjectIds)
      ..writeByte(5)
      ..write(obj.defaultRuleId)
      ..writeByte(6)
      ..write(obj.caseSensitiveComparison)
      ..writeByte(7)
      ..write(obj.defaultExportFormatIndex)
      ..writeByte(8)
      ..write(obj.confirmBeforeSync)
      ..writeByte(9)
      ..write(obj.enableLogging);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportFormatAdapter extends TypeAdapter<ExportFormat> {
  @override
  final int typeId = 5;

  @override
  ExportFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportFormat.json;
      case 1:
        return ExportFormat.csv;
      case 2:
        return ExportFormat.markdown;
      default:
        return ExportFormat.json;
    }
  }

  @override
  void write(BinaryWriter writer, ExportFormat obj) {
    switch (obj) {
      case ExportFormat.json:
        writer.writeByte(0);
        break;
      case ExportFormat.csv:
        writer.writeByte(1);
        break;
      case ExportFormat.markdown:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
