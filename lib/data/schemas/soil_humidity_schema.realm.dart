// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soil_humidity_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SoilHumidityRecord extends _SoilHumidityRecord
    with RealmEntity, RealmObjectBase, RealmObject {
  SoilHumidityRecord(int timestamp, double value) {
    RealmObjectBase.set(this, 'timestamp', timestamp);
    RealmObjectBase.set(this, 'value', value);
  }

  SoilHumidityRecord._();

  @override
  int get timestamp => RealmObjectBase.get<int>(this, 'timestamp') as int;
  @override
  set timestamp(int value) => RealmObjectBase.set(this, 'timestamp', value);

  @override
  double get value => RealmObjectBase.get<double>(this, 'value') as double;
  @override
  set value(double value) => RealmObjectBase.set(this, 'value', value);

  @override
  Stream<RealmObjectChanges<SoilHumidityRecord>> get changes =>
      RealmObjectBase.getChanges<SoilHumidityRecord>(this);

  @override
  Stream<RealmObjectChanges<SoilHumidityRecord>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SoilHumidityRecord>(this, keyPaths);

  @override
  SoilHumidityRecord freeze() =>
      RealmObjectBase.freezeObject<SoilHumidityRecord>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toEJson(),
      'value': value.toEJson(),
    };
  }

  static EJsonValue _toEJson(SoilHumidityRecord value) => value.toEJson();
  static SoilHumidityRecord _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'timestamp': EJsonValue timestamp, 'value': EJsonValue value} =>
        SoilHumidityRecord(fromEJson(timestamp), fromEJson(value)),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SoilHumidityRecord._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SoilHumidityRecord,
      'SoilHumidityRecord',
      [
        SchemaProperty('timestamp', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('value', RealmPropertyType.double),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
