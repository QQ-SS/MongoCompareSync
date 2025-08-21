import 'package:json_annotation/json_annotation.dart';

part 'collection.g.dart';

@JsonSerializable()
class MongoCollection {
  final String name;
  final String database;
  final String connectionId;
  final int documentCount;
  final List<String> indexes;

  MongoCollection({
    required this.name,
    required this.database,
    required this.connectionId,
    this.documentCount = 0,
    this.indexes = const [],
  });

  factory MongoCollection.fromJson(Map<String, dynamic> json) =>
      _$MongoCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$MongoCollectionToJson(this);

  MongoCollection copyWith({
    String? name,
    String? database,
    String? connectionId,
    int? documentCount,
    List<String>? indexes,
  }) {
    return MongoCollection(
      name: name ?? this.name,
      database: database ?? this.database,
      connectionId: connectionId ?? this.connectionId,
      documentCount: documentCount ?? this.documentCount,
      indexes: indexes ?? this.indexes,
    );
  }
}
