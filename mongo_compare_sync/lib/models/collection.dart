import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'collection.freezed.dart';
part 'collection.g.dart';

@freezed
class MongoCollection with _$MongoCollection {
  const factory MongoCollection({
    required String name,
    required String database,
    required String connectionId,
    @Default(0) int documentCount,
    @Default([]) List<String> indexes,
  }) = _MongoCollection;

  factory MongoCollection.fromJson(Map<String, dynamic> json) =>
      _$MongoCollectionFromJson(json);
}
