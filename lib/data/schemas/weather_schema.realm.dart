// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class WeatherRecord extends _WeatherRecord
    with RealmEntity, RealmObjectBase, RealmObject {
  WeatherRecord(
    int timestamp,
    double temperature,
    double humidity,
    double radiation,
    double precipitation,
  ) {
    RealmObjectBase.set(this, 'timestamp', timestamp);
    RealmObjectBase.set(this, 'temperature', temperature);
    RealmObjectBase.set(this, 'humidity', humidity);
    RealmObjectBase.set(this, 'radiation', radiation);
    RealmObjectBase.set(this, 'precipitation', precipitation);
  }

  WeatherRecord._();

  @override
  int get timestamp => RealmObjectBase.get<int>(this, 'timestamp') as int;
  @override
  set timestamp(int value) => RealmObjectBase.set(this, 'timestamp', value);

  @override
  double get temperature =>
      RealmObjectBase.get<double>(this, 'temperature') as double;
  @override
  set temperature(double value) =>
      RealmObjectBase.set(this, 'temperature', value);

  @override
  double get humidity =>
      RealmObjectBase.get<double>(this, 'humidity') as double;
  @override
  set humidity(double value) => RealmObjectBase.set(this, 'humidity', value);

  @override
  double get radiation =>
      RealmObjectBase.get<double>(this, 'radiation') as double;
  @override
  set radiation(double value) => RealmObjectBase.set(this, 'radiation', value);

  @override
  double get precipitation =>
      RealmObjectBase.get<double>(this, 'precipitation') as double;
  @override
  set precipitation(double value) =>
      RealmObjectBase.set(this, 'precipitation', value);

  @override
  Stream<RealmObjectChanges<WeatherRecord>> get changes =>
      RealmObjectBase.getChanges<WeatherRecord>(this);

  @override
  Stream<RealmObjectChanges<WeatherRecord>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<WeatherRecord>(this, keyPaths);

  @override
  WeatherRecord freeze() => RealmObjectBase.freezeObject<WeatherRecord>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toEJson(),
      'temperature': temperature.toEJson(),
      'humidity': humidity.toEJson(),
      'radiation': radiation.toEJson(),
      'precipitation': precipitation.toEJson(),
    };
  }

  static EJsonValue _toEJson(WeatherRecord value) => value.toEJson();
  static WeatherRecord _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'timestamp': EJsonValue timestamp,
        'temperature': EJsonValue temperature,
        'humidity': EJsonValue humidity,
        'radiation': EJsonValue radiation,
        'precipitation': EJsonValue precipitation,
      } =>
        WeatherRecord(
          fromEJson(timestamp),
          fromEJson(temperature),
          fromEJson(humidity),
          fromEJson(radiation),
          fromEJson(precipitation),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(WeatherRecord._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      WeatherRecord,
      'WeatherRecord',
      [
        SchemaProperty('timestamp', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('temperature', RealmPropertyType.double),
        SchemaProperty('humidity', RealmPropertyType.double),
        SchemaProperty('radiation', RealmPropertyType.double),
        SchemaProperty('precipitation', RealmPropertyType.double),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
