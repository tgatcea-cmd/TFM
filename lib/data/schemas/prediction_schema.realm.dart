// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class PredictionRecord extends _PredictionRecord
    with RealmEntity, RealmObjectBase, RealmObject {
  PredictionRecord(
    int timestamp,
    double predictedHumidity,
    String recommendation,
  ) {
    RealmObjectBase.set(this, 'timestamp', timestamp);
    RealmObjectBase.set(this, 'predictedHumidity', predictedHumidity);
    RealmObjectBase.set(this, 'recommendation', recommendation);
  }

  PredictionRecord._();

  @override
  int get timestamp => RealmObjectBase.get<int>(this, 'timestamp') as int;
  @override
  set timestamp(int value) => RealmObjectBase.set(this, 'timestamp', value);

  @override
  double get predictedHumidity =>
      RealmObjectBase.get<double>(this, 'predictedHumidity') as double;
  @override
  set predictedHumidity(double value) =>
      RealmObjectBase.set(this, 'predictedHumidity', value);

  @override
  String get recommendation =>
      RealmObjectBase.get<String>(this, 'recommendation') as String;
  @override
  set recommendation(String value) =>
      RealmObjectBase.set(this, 'recommendation', value);

  @override
  Stream<RealmObjectChanges<PredictionRecord>> get changes =>
      RealmObjectBase.getChanges<PredictionRecord>(this);

  @override
  Stream<RealmObjectChanges<PredictionRecord>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<PredictionRecord>(this, keyPaths);

  @override
  PredictionRecord freeze() =>
      RealmObjectBase.freezeObject<PredictionRecord>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toEJson(),
      'predictedHumidity': predictedHumidity.toEJson(),
      'recommendation': recommendation.toEJson(),
    };
  }

  static EJsonValue _toEJson(PredictionRecord value) => value.toEJson();
  static PredictionRecord _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'timestamp': EJsonValue timestamp,
        'predictedHumidity': EJsonValue predictedHumidity,
        'recommendation': EJsonValue recommendation,
      } =>
        PredictionRecord(
          fromEJson(timestamp),
          fromEJson(predictedHumidity),
          fromEJson(recommendation),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PredictionRecord._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      PredictionRecord,
      'PredictionRecord',
      [
        SchemaProperty('timestamp', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('predictedHumidity', RealmPropertyType.double),
        SchemaProperty('recommendation', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
