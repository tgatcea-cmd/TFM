// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class LocationSettings extends _LocationSettings
    with RealmEntity, RealmObjectBase, RealmObject {
  LocationSettings(int id, double latitude, double longitude, bool isGpsBased) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'latitude', latitude);
    RealmObjectBase.set(this, 'longitude', longitude);
    RealmObjectBase.set(this, 'isGpsBased', isGpsBased);
  }

  LocationSettings._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  double get latitude =>
      RealmObjectBase.get<double>(this, 'latitude') as double;
  @override
  set latitude(double value) => RealmObjectBase.set(this, 'latitude', value);

  @override
  double get longitude =>
      RealmObjectBase.get<double>(this, 'longitude') as double;
  @override
  set longitude(double value) => RealmObjectBase.set(this, 'longitude', value);

  @override
  bool get isGpsBased => RealmObjectBase.get<bool>(this, 'isGpsBased') as bool;
  @override
  set isGpsBased(bool value) => RealmObjectBase.set(this, 'isGpsBased', value);

  @override
  Stream<RealmObjectChanges<LocationSettings>> get changes =>
      RealmObjectBase.getChanges<LocationSettings>(this);

  @override
  Stream<RealmObjectChanges<LocationSettings>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<LocationSettings>(this, keyPaths);

  @override
  LocationSettings freeze() =>
      RealmObjectBase.freezeObject<LocationSettings>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'latitude': latitude.toEJson(),
      'longitude': longitude.toEJson(),
      'isGpsBased': isGpsBased.toEJson(),
    };
  }

  static EJsonValue _toEJson(LocationSettings value) => value.toEJson();
  static LocationSettings _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'latitude': EJsonValue latitude,
        'longitude': EJsonValue longitude,
        'isGpsBased': EJsonValue isGpsBased,
      } =>
        LocationSettings(
          fromEJson(id),
          fromEJson(latitude),
          fromEJson(longitude),
          fromEJson(isGpsBased),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(LocationSettings._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      LocationSettings,
      'LocationSettings',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('latitude', RealmPropertyType.double),
        SchemaProperty('longitude', RealmPropertyType.double),
        SchemaProperty('isGpsBased', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
