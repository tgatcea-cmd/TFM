// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class AppSettings extends _AppSettings
    with RealmEntity, RealmObjectBase, RealmObject {
  AppSettings(
    int id,
    String tfmServerUrl,
    int tfmServerPort,
    String tfmServerApiKey,
    String selectedTfliteModel,
    bool invertModelOutput,
    bool permitOpenMeteoFill,
    bool alwaysForceInference,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'tfmServerUrl', tfmServerUrl);
    RealmObjectBase.set(this, 'tfmServerPort', tfmServerPort);
    RealmObjectBase.set(this, 'tfmServerApiKey', tfmServerApiKey);
    RealmObjectBase.set(this, 'selectedTfliteModel', selectedTfliteModel);
    RealmObjectBase.set(this, 'invertModelOutput', invertModelOutput);
    RealmObjectBase.set(this, 'permitOpenMeteoFill', permitOpenMeteoFill);
    RealmObjectBase.set(this, 'alwaysForceInference', alwaysForceInference);
  }

  AppSettings._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get tfmServerUrl =>
      RealmObjectBase.get<String>(this, 'tfmServerUrl') as String;
  @override
  set tfmServerUrl(String value) =>
      RealmObjectBase.set(this, 'tfmServerUrl', value);

  @override
  int get tfmServerPort =>
      RealmObjectBase.get<int>(this, 'tfmServerPort') as int;
  @override
  set tfmServerPort(int value) =>
      RealmObjectBase.set(this, 'tfmServerPort', value);

  @override
  String get tfmServerApiKey =>
      RealmObjectBase.get<String>(this, 'tfmServerApiKey') as String;
  @override
  set tfmServerApiKey(String value) =>
      RealmObjectBase.set(this, 'tfmServerApiKey', value);

  @override
  String get selectedTfliteModel =>
      RealmObjectBase.get<String>(this, 'selectedTfliteModel') as String;
  @override
  set selectedTfliteModel(String value) =>
      RealmObjectBase.set(this, 'selectedTfliteModel', value);

  @override
  bool get invertModelOutput =>
      RealmObjectBase.get<bool>(this, 'invertModelOutput') as bool;
  @override
  set invertModelOutput(bool value) =>
      RealmObjectBase.set(this, 'invertModelOutput', value);

  @override
  bool get permitOpenMeteoFill =>
      RealmObjectBase.get<bool>(this, 'permitOpenMeteoFill') as bool;
  @override
  set permitOpenMeteoFill(bool value) =>
      RealmObjectBase.set(this, 'permitOpenMeteoFill', value);

  @override
  bool get alwaysForceInference =>
      RealmObjectBase.get<bool>(this, 'alwaysForceInference') as bool;
  @override
  set alwaysForceInference(bool value) =>
      RealmObjectBase.set(this, 'alwaysForceInference', value);

  @override
  Stream<RealmObjectChanges<AppSettings>> get changes =>
      RealmObjectBase.getChanges<AppSettings>(this);

  @override
  Stream<RealmObjectChanges<AppSettings>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<AppSettings>(this, keyPaths);

  @override
  AppSettings freeze() => RealmObjectBase.freezeObject<AppSettings>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'tfmServerUrl': tfmServerUrl.toEJson(),
      'tfmServerPort': tfmServerPort.toEJson(),
      'tfmServerApiKey': tfmServerApiKey.toEJson(),
      'selectedTfliteModel': selectedTfliteModel.toEJson(),
      'invertModelOutput': invertModelOutput.toEJson(),
      'permitOpenMeteoFill': permitOpenMeteoFill.toEJson(),
      'alwaysForceInference': alwaysForceInference.toEJson(),
    };
  }

  static EJsonValue _toEJson(AppSettings value) => value.toEJson();
  static AppSettings _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'tfmServerUrl': EJsonValue tfmServerUrl,
        'tfmServerPort': EJsonValue tfmServerPort,
        'tfmServerApiKey': EJsonValue tfmServerApiKey,
        'selectedTfliteModel': EJsonValue selectedTfliteModel,
        'invertModelOutput': EJsonValue invertModelOutput,
        'permitOpenMeteoFill': EJsonValue permitOpenMeteoFill,
        'alwaysForceInference': EJsonValue alwaysForceInference,
      } =>
        AppSettings(
          fromEJson(id),
          fromEJson(tfmServerUrl),
          fromEJson(tfmServerPort),
          fromEJson(tfmServerApiKey),
          fromEJson(selectedTfliteModel),
          fromEJson(invertModelOutput),
          fromEJson(permitOpenMeteoFill),
          fromEJson(alwaysForceInference),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(AppSettings._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      AppSettings,
      'AppSettings',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('tfmServerUrl', RealmPropertyType.string),
        SchemaProperty('tfmServerPort', RealmPropertyType.int),
        SchemaProperty('tfmServerApiKey', RealmPropertyType.string),
        SchemaProperty('selectedTfliteModel', RealmPropertyType.string),
        SchemaProperty('invertModelOutput', RealmPropertyType.bool),
        SchemaProperty('permitOpenMeteoFill', RealmPropertyType.bool),
        SchemaProperty('alwaysForceInference', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
