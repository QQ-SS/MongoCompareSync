// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      id: json['id'] as String,
      themeModeIndex: (json['themeModeIndex'] as num?)?.toInt() ?? 0,
      locale: json['locale'] as String? ?? 'zh_CN',
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      showObjectIds: json['showObjectIds'] as bool? ?? true,
      defaultRuleId: json['defaultRuleId'] as String?,
      caseSensitiveComparison: json['caseSensitiveComparison'] as bool? ?? true,
      defaultExportFormatIndex:
          (json['defaultExportFormatIndex'] as num?)?.toInt() ?? 0,
      confirmBeforeSync: json['confirmBeforeSync'] as bool? ?? true,
      enableLogging: json['enableLogging'] as bool? ?? false,
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'themeModeIndex': instance.themeModeIndex,
      'locale': instance.locale,
      'pageSize': instance.pageSize,
      'showObjectIds': instance.showObjectIds,
      'defaultRuleId': instance.defaultRuleId,
      'caseSensitiveComparison': instance.caseSensitiveComparison,
      'defaultExportFormatIndex': instance.defaultExportFormatIndex,
      'confirmBeforeSync': instance.confirmBeforeSync,
      'enableLogging': instance.enableLogging,
    };
