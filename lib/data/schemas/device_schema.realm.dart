// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SavedDevice extends _SavedDevice
    with RealmEntity, RealmObjectBase, RealmObject {
  SavedDevice(String id, String name) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
  }

  SavedDevice._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  Stream<RealmObjectChanges<SavedDevice>> get changes =>
      RealmObjectBase.getChanges<SavedDevice>(this);

  @override
  Stream<RealmObjectChanges<SavedDevice>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SavedDevice>(this, keyPaths);

  @override
  SavedDevice freeze() => RealmObjectBase.freezeObject<SavedDevice>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{'id': id.toEJson(), 'name': name.toEJson()};
  }

  static EJsonValue _toEJson(SavedDevice value) => value.toEJson();
  static SavedDevice _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id, 'name': EJsonValue name} => SavedDevice(
        fromEJson(id),
        fromEJson(name),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SavedDevice._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SavedDevice,
      'SavedDevice',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
