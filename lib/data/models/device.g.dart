// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDeviceCollection on Isar {
  IsarCollection<Device> get devices => this.collection();
}

const DeviceSchema = CollectionSchema(
  name: r'Device',
  id: 3491430514663294648,
  properties: {
    r'deviceIdentifier': PropertySchema(
      id: 0,
      name: r'deviceIdentifier',
      type: IsarType.string,
    ),
    r'handshakePassword': PropertySchema(
      id: 1,
      name: r'handshakePassword',
      type: IsarType.string,
    ),
    r'historicValues': PropertySchema(
      id: 2,
      name: r'historicValues',
      type: IsarType.objectList,

      target: r'HistoricValue',
    ),
    r'isSynced': PropertySchema(id: 3, name: r'isSynced', type: IsarType.bool),
    r'latestInferenceTriggerDate': PropertySchema(
      id: 4,
      name: r'latestInferenceTriggerDate',
      type: IsarType.dateTime,
    ),
    r'latestSynchronizedTime': PropertySchema(
      id: 5,
      name: r'latestSynchronizedTime',
      type: IsarType.dateTime,
    ),
    r'latitude': PropertySchema(
      id: 6,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'localInferenceCapabilities': PropertySchema(
      id: 7,
      name: r'localInferenceCapabilities',
      type: IsarType.bool,
    ),
    r'longitude': PropertySchema(
      id: 8,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'loraEnabled': PropertySchema(
      id: 9,
      name: r'loraEnabled',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(id: 10, name: r'name', type: IsarType.string),
    r'newPredictions': PropertySchema(
      id: 11,
      name: r'newPredictions',
      type: IsarType.objectList,

      target: r'Prediction',
    ),
    r'previousPredictions': PropertySchema(
      id: 12,
      name: r'previousPredictions',
      type: IsarType.objectList,

      target: r'Prediction',
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _deviceEstimateSize,
  serialize: _deviceSerialize,
  deserialize: _deviceDeserialize,
  deserializeProp: _deviceDeserializeProp,
  idName: r'id',
  indexes: {
    r'deviceIdentifier': IndexSchema(
      id: 8570335694319598033,
      name: r'deviceIdentifier',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deviceIdentifier',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'HistoricValue': HistoricValueSchema,
    r'Prediction': PredictionSchema,
  },

  getId: _deviceGetId,
  getLinks: _deviceGetLinks,
  attach: _deviceAttach,
  version: '3.3.2',
);

int _deviceEstimateSize(
  Device object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceIdentifier.length * 3;
  bytesCount += 3 + object.handshakePassword.length * 3;
  bytesCount += 3 + object.historicValues.length * 3;
  {
    final offsets = allOffsets[HistoricValue]!;
    for (var i = 0; i < object.historicValues.length; i++) {
      final value = object.historicValues[i];
      bytesCount += HistoricValueSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.newPredictions.length * 3;
  {
    final offsets = allOffsets[Prediction]!;
    for (var i = 0; i < object.newPredictions.length; i++) {
      final value = object.newPredictions[i];
      bytesCount += PredictionSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.previousPredictions.length * 3;
  {
    final offsets = allOffsets[Prediction]!;
    for (var i = 0; i < object.previousPredictions.length; i++) {
      final value = object.previousPredictions[i];
      bytesCount += PredictionSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _deviceSerialize(
  Device object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deviceIdentifier);
  writer.writeString(offsets[1], object.handshakePassword);
  writer.writeObjectList<HistoricValue>(
    offsets[2],
    allOffsets,
    HistoricValueSchema.serialize,
    object.historicValues,
  );
  writer.writeBool(offsets[3], object.isSynced);
  writer.writeDateTime(offsets[4], object.latestInferenceTriggerDate);
  writer.writeDateTime(offsets[5], object.latestSynchronizedTime);
  writer.writeDouble(offsets[6], object.latitude);
  writer.writeBool(offsets[7], object.localInferenceCapabilities);
  writer.writeDouble(offsets[8], object.longitude);
  writer.writeBool(offsets[9], object.loraEnabled);
  writer.writeString(offsets[10], object.name);
  writer.writeObjectList<Prediction>(
    offsets[11],
    allOffsets,
    PredictionSchema.serialize,
    object.newPredictions,
  );
  writer.writeObjectList<Prediction>(
    offsets[12],
    allOffsets,
    PredictionSchema.serialize,
    object.previousPredictions,
  );
  writer.writeDateTime(offsets[13], object.updatedAt);
}

Device _deviceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Device();
  object.deviceIdentifier = reader.readString(offsets[0]);
  object.handshakePassword = reader.readString(offsets[1]);
  object.historicValues =
      reader.readObjectList<HistoricValue>(
        offsets[2],
        HistoricValueSchema.deserialize,
        allOffsets,
        HistoricValue(),
      ) ??
      [];
  object.id = id;
  object.isSynced = reader.readBool(offsets[3]);
  object.latestInferenceTriggerDate = reader.readDateTimeOrNull(offsets[4]);
  object.latestSynchronizedTime = reader.readDateTimeOrNull(offsets[5]);
  object.latitude = reader.readDoubleOrNull(offsets[6]);
  object.localInferenceCapabilities = reader.readBool(offsets[7]);
  object.longitude = reader.readDoubleOrNull(offsets[8]);
  object.loraEnabled = reader.readBool(offsets[9]);
  object.name = reader.readString(offsets[10]);
  object.newPredictions =
      reader.readObjectList<Prediction>(
        offsets[11],
        PredictionSchema.deserialize,
        allOffsets,
        Prediction(),
      ) ??
      [];
  object.previousPredictions =
      reader.readObjectList<Prediction>(
        offsets[12],
        PredictionSchema.deserialize,
        allOffsets,
        Prediction(),
      ) ??
      [];
  object.updatedAt = reader.readDateTime(offsets[13]);
  return object;
}

P _deviceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readObjectList<HistoricValue>(
                offset,
                HistoricValueSchema.deserialize,
                allOffsets,
                HistoricValue(),
              ) ??
              [])
          as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readObjectList<Prediction>(
                offset,
                PredictionSchema.deserialize,
                allOffsets,
                Prediction(),
              ) ??
              [])
          as P;
    case 12:
      return (reader.readObjectList<Prediction>(
                offset,
                PredictionSchema.deserialize,
                allOffsets,
                Prediction(),
              ) ??
              [])
          as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _deviceGetId(Device object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _deviceGetLinks(Device object) {
  return [];
}

void _deviceAttach(IsarCollection<dynamic> col, Id id, Device object) {
  object.id = id;
}

extension DeviceByIndex on IsarCollection<Device> {
  Future<Device?> getByDeviceIdentifier(String deviceIdentifier) {
    return getByIndex(r'deviceIdentifier', [deviceIdentifier]);
  }

  Device? getByDeviceIdentifierSync(String deviceIdentifier) {
    return getByIndexSync(r'deviceIdentifier', [deviceIdentifier]);
  }

  Future<bool> deleteByDeviceIdentifier(String deviceIdentifier) {
    return deleteByIndex(r'deviceIdentifier', [deviceIdentifier]);
  }

  bool deleteByDeviceIdentifierSync(String deviceIdentifier) {
    return deleteByIndexSync(r'deviceIdentifier', [deviceIdentifier]);
  }

  Future<List<Device?>> getAllByDeviceIdentifier(
    List<String> deviceIdentifierValues,
  ) {
    final values = deviceIdentifierValues.map((e) => [e]).toList();
    return getAllByIndex(r'deviceIdentifier', values);
  }

  List<Device?> getAllByDeviceIdentifierSync(
    List<String> deviceIdentifierValues,
  ) {
    final values = deviceIdentifierValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'deviceIdentifier', values);
  }

  Future<int> deleteAllByDeviceIdentifier(List<String> deviceIdentifierValues) {
    final values = deviceIdentifierValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'deviceIdentifier', values);
  }

  int deleteAllByDeviceIdentifierSync(List<String> deviceIdentifierValues) {
    final values = deviceIdentifierValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'deviceIdentifier', values);
  }

  Future<Id> putByDeviceIdentifier(Device object) {
    return putByIndex(r'deviceIdentifier', object);
  }

  Id putByDeviceIdentifierSync(Device object, {bool saveLinks = true}) {
    return putByIndexSync(r'deviceIdentifier', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDeviceIdentifier(List<Device> objects) {
    return putAllByIndex(r'deviceIdentifier', objects);
  }

  List<Id> putAllByDeviceIdentifierSync(
    List<Device> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'deviceIdentifier',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension DeviceQueryWhereSort on QueryBuilder<Device, Device, QWhere> {
  QueryBuilder<Device, Device, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DeviceQueryWhere on QueryBuilder<Device, Device, QWhereClause> {
  QueryBuilder<Device, Device, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> deviceIdentifierEqualTo(
    String deviceIdentifier,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'deviceIdentifier',
          value: [deviceIdentifier],
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> deviceIdentifierNotEqualTo(
    String deviceIdentifier,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceIdentifier',
                lower: [],
                upper: [deviceIdentifier],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceIdentifier',
                lower: [deviceIdentifier],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceIdentifier',
                lower: [deviceIdentifier],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceIdentifier',
                lower: [],
                upper: [deviceIdentifier],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DeviceQueryFilter on QueryBuilder<Device, Device, QFilterCondition> {
  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  deviceIdentifierGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceIdentifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  deviceIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deviceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> deviceIdentifierMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deviceIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  deviceIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  deviceIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  handshakePasswordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'handshakePassword',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  handshakePasswordStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'handshakePassword',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> handshakePasswordMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'handshakePassword',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  handshakePasswordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'handshakePassword', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  handshakePasswordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'handshakePassword', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  historicValuesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'historicValues', length, true, length, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historicValuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'historicValues', 0, true, 0, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  historicValuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'historicValues', 0, false, 999999, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  historicValuesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'historicValues', 0, true, length, include);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  historicValuesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'historicValues', length, include, 999999, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  historicValuesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'historicValues',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> isSyncedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSynced', value: value),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latestInferenceTriggerDate'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(
          property: r'latestInferenceTriggerDate',
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latestInferenceTriggerDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latestInferenceTriggerDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latestInferenceTriggerDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestInferenceTriggerDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latestInferenceTriggerDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latestSynchronizedTime'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latestSynchronizedTime'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latestSynchronizedTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latestSynchronizedTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latestSynchronizedTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  latestSynchronizedTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latestSynchronizedTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  localInferenceCapabilitiesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localInferenceCapabilities',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> loraEnabledEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'loraEnabled', value: value),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  newPredictionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'newPredictions', length, true, length, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> newPredictionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'newPredictions', 0, true, 0, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  newPredictionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'newPredictions', 0, false, 999999, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  newPredictionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'newPredictions', 0, true, length, include);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  newPredictionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'newPredictions', length, include, 999999, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  newPredictionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'newPredictions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'previousPredictions',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'previousPredictions', 0, true, 0, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'previousPredictions', 0, false, 999999, true);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'previousPredictions', 0, true, length, include);
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'previousPredictions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'previousPredictions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DeviceQueryObject on QueryBuilder<Device, Device, QFilterCondition> {
  QueryBuilder<Device, Device, QAfterFilterCondition> historicValuesElement(
    FilterQuery<HistoricValue> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'historicValues');
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> newPredictionsElement(
    FilterQuery<Prediction> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'newPredictions');
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
  previousPredictionsElement(FilterQuery<Prediction> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'previousPredictions');
    });
  }
}

extension DeviceQueryLinks on QueryBuilder<Device, Device, QFilterCondition> {}

extension DeviceQuerySortBy on QueryBuilder<Device, Device, QSortBy> {
  QueryBuilder<Device, Device, QAfterSortBy> sortByDeviceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByDeviceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByHandshakePassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'handshakePassword', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByHandshakePasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'handshakePassword', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  sortByLatestInferenceTriggerDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestInferenceTriggerDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  sortByLatestInferenceTriggerDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestInferenceTriggerDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLatestSynchronizedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestSynchronizedTime', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  sortByLatestSynchronizedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestSynchronizedTime', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  sortByLocalInferenceCapabilities() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localInferenceCapabilities', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  sortByLocalInferenceCapabilitiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localInferenceCapabilities', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLoraEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loraEnabled', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLoraEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loraEnabled', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DeviceQuerySortThenBy on QueryBuilder<Device, Device, QSortThenBy> {
  QueryBuilder<Device, Device, QAfterSortBy> thenByDeviceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByDeviceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByHandshakePassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'handshakePassword', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByHandshakePasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'handshakePassword', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  thenByLatestInferenceTriggerDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestInferenceTriggerDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  thenByLatestInferenceTriggerDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestInferenceTriggerDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLatestSynchronizedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestSynchronizedTime', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  thenByLatestSynchronizedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestSynchronizedTime', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  thenByLocalInferenceCapabilities() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localInferenceCapabilities', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy>
  thenByLocalInferenceCapabilitiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localInferenceCapabilities', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLoraEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loraEnabled', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLoraEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loraEnabled', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DeviceQueryWhereDistinct on QueryBuilder<Device, Device, QDistinct> {
  QueryBuilder<Device, Device, QDistinct> distinctByDeviceIdentifier({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'deviceIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByHandshakePassword({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'handshakePassword',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Device, Device, QDistinct>
  distinctByLatestInferenceTriggerDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestInferenceTriggerDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByLatestSynchronizedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestSynchronizedTime');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<Device, Device, QDistinct>
  distinctByLocalInferenceCapabilities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localInferenceCapabilities');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByLoraEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loraEnabled');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DeviceQueryProperty on QueryBuilder<Device, Device, QQueryProperty> {
  QueryBuilder<Device, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> deviceIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceIdentifier');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> handshakePasswordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'handshakePassword');
    });
  }

  QueryBuilder<Device, List<HistoricValue>, QQueryOperations>
  historicValuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'historicValues');
    });
  }

  QueryBuilder<Device, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations>
  latestInferenceTriggerDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestInferenceTriggerDate');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations>
  latestSynchronizedTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestSynchronizedTime');
    });
  }

  QueryBuilder<Device, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<Device, bool, QQueryOperations>
  localInferenceCapabilitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localInferenceCapabilities');
    });
  }

  QueryBuilder<Device, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<Device, bool, QQueryOperations> loraEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loraEnabled');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Device, List<Prediction>, QQueryOperations>
  newPredictionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newPredictions');
    });
  }

  QueryBuilder<Device, List<Prediction>, QQueryOperations>
  previousPredictionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'previousPredictions');
    });
  }

  QueryBuilder<Device, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const HistoricValueSchema = Schema(
  name: r'HistoricValue',
  id: 3448619404271591874,
  properties: {
    r'depthCm': PropertySchema(id: 0, name: r'depthCm', type: IsarType.double),
    r'kind': PropertySchema(id: 1, name: r'kind', type: IsarType.string),
    r'port': PropertySchema(id: 2, name: r'port', type: IsarType.long),
    r'tsMs': PropertySchema(id: 3, name: r'tsMs', type: IsarType.long),
    r'value': PropertySchema(id: 4, name: r'value', type: IsarType.double),
  },

  estimateSize: _historicValueEstimateSize,
  serialize: _historicValueSerialize,
  deserialize: _historicValueDeserialize,
  deserializeProp: _historicValueDeserializeProp,
);

int _historicValueEstimateSize(
  HistoricValue object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.kind;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _historicValueSerialize(
  HistoricValue object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.depthCm);
  writer.writeString(offsets[1], object.kind);
  writer.writeLong(offsets[2], object.port);
  writer.writeLong(offsets[3], object.tsMs);
  writer.writeDouble(offsets[4], object.value);
}

HistoricValue _historicValueDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HistoricValue();
  object.depthCm = reader.readDoubleOrNull(offsets[0]);
  object.kind = reader.readStringOrNull(offsets[1]);
  object.port = reader.readLongOrNull(offsets[2]);
  object.tsMs = reader.readLongOrNull(offsets[3]);
  object.value = reader.readDoubleOrNull(offsets[4]);
  return object;
}

P _historicValueDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension HistoricValueQueryFilter
    on QueryBuilder<HistoricValue, HistoricValue, QFilterCondition> {
  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'depthCm'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'depthCm'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'depthCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'depthCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'depthCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  depthCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'depthCm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'kind'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'kind'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> kindEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> kindBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> kindMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  portIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'port'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  portIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'port'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> portEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'port', value: value),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  portGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'port',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  portLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'port',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> portBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'port',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  tsMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tsMs'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  tsMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tsMs'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> tsMsEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tsMs', value: value),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  tsMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tsMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  tsMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tsMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition> tsMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tsMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'value'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'value'),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoricValue, HistoricValue, QAfterFilterCondition>
  valueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'value',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension HistoricValueQueryObject
    on QueryBuilder<HistoricValue, HistoricValue, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const PredictionSchema = Schema(
  name: r'Prediction',
  id: 2351554733480628633,
  properties: {
    r'confidence': PropertySchema(
      id: 0,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'kind': PropertySchema(id: 1, name: r'kind', type: IsarType.string),
    r'model': PropertySchema(id: 2, name: r'model', type: IsarType.string),
    r'port': PropertySchema(id: 3, name: r'port', type: IsarType.long),
    r'tsMs': PropertySchema(id: 4, name: r'tsMs', type: IsarType.long),
    r'value': PropertySchema(id: 5, name: r'value', type: IsarType.double),
  },

  estimateSize: _predictionEstimateSize,
  serialize: _predictionSerialize,
  deserialize: _predictionDeserialize,
  deserializeProp: _predictionDeserializeProp,
);

int _predictionEstimateSize(
  Prediction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.kind;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.model;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _predictionSerialize(
  Prediction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.confidence);
  writer.writeString(offsets[1], object.kind);
  writer.writeString(offsets[2], object.model);
  writer.writeLong(offsets[3], object.port);
  writer.writeLong(offsets[4], object.tsMs);
  writer.writeDouble(offsets[5], object.value);
}

Prediction _predictionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Prediction();
  object.confidence = reader.readDoubleOrNull(offsets[0]);
  object.kind = reader.readStringOrNull(offsets[1]);
  object.model = reader.readStringOrNull(offsets[2]);
  object.port = reader.readLongOrNull(offsets[3]);
  object.tsMs = reader.readLongOrNull(offsets[4]);
  object.value = reader.readDoubleOrNull(offsets[5]);
  return object;
}

P _predictionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension PredictionQueryFilter
    on QueryBuilder<Prediction, Prediction, QFilterCondition> {
  QueryBuilder<Prediction, Prediction, QAfterFilterCondition>
  confidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'confidence'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition>
  confidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'confidence'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> confidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition>
  confidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition>
  confidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> confidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'confidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'kind'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'kind'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'model'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'model'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'model',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'model',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'model',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> modelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'model', value: ''),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition>
  modelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'model', value: ''),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'port'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'port'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'port', value: value),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'port',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'port',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> portBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'port',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tsMs'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tsMs'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tsMs', value: value),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tsMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tsMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> tsMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tsMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'value'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'value'),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Prediction, Prediction, QAfterFilterCondition> valueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'value',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension PredictionQueryObject
    on QueryBuilder<Prediction, Prediction, QFilterCondition> {}
