// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsCollection on Isar {
  IsarCollection<AppSettings> get appSettings => this.collection();
}

const AppSettingsSchema = CollectionSchema(
  name: r'AppSettings',
  id: -5633561779022347008,
  properties: {
    r'agronomicDayEnd': PropertySchema(
      id: 0,
      name: r'agronomicDayEnd',
      type: IsarType.long,
    ),
    r'agronomicDayStart': PropertySchema(
      id: 1,
      name: r'agronomicDayStart',
      type: IsarType.long,
    ),
    r'alwaysForceInference': PropertySchema(
      id: 2,
      name: r'alwaysForceInference',
      type: IsarType.bool,
    ),
    r'gpsLat': PropertySchema(id: 3, name: r'gpsLat', type: IsarType.double),
    r'gpsLon': PropertySchema(id: 4, name: r'gpsLon', type: IsarType.double),
    r'invertModelOutput': PropertySchema(
      id: 5,
      name: r'invertModelOutput',
      type: IsarType.bool,
    ),
    r'isFirstTime': PropertySchema(
      id: 6,
      name: r'isFirstTime',
      type: IsarType.bool,
    ),
    r'isGpsEnabled': PropertySchema(
      id: 7,
      name: r'isGpsEnabled',
      type: IsarType.bool,
    ),
    r'manualLat': PropertySchema(
      id: 8,
      name: r'manualLat',
      type: IsarType.double,
    ),
    r'manualLon': PropertySchema(
      id: 9,
      name: r'manualLon',
      type: IsarType.double,
    ),
    r'minHumidity': PropertySchema(
      id: 10,
      name: r'minHumidity',
      type: IsarType.double,
    ),
    r'permitOpenMeteoFill': PropertySchema(
      id: 11,
      name: r'permitOpenMeteoFill',
      type: IsarType.bool,
    ),
    r'selectedTfliteModel': PropertySchema(
      id: 12,
      name: r'selectedTfliteModel',
      type: IsarType.string,
    ),
    r'syncScheduleHours': PropertySchema(
      id: 13,
      name: r'syncScheduleHours',
      type: IsarType.long,
    ),
    r'tfmServerApiKey': PropertySchema(
      id: 14,
      name: r'tfmServerApiKey',
      type: IsarType.string,
    ),
    r'tfmServerPort': PropertySchema(
      id: 15,
      name: r'tfmServerPort',
      type: IsarType.long,
    ),
    r'tfmServerScheme': PropertySchema(
      id: 16,
      name: r'tfmServerScheme',
      type: IsarType.string,
    ),
    r'tfmServerUrl': PropertySchema(
      id: 17,
      name: r'tfmServerUrl',
      type: IsarType.string,
    ),
    r'themeMode': PropertySchema(
      id: 18,
      name: r'themeMode',
      type: IsarType.string,
    ),
  },

  estimateSize: _appSettingsEstimateSize,
  serialize: _appSettingsSerialize,
  deserialize: _appSettingsDeserialize,
  deserializeProp: _appSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _appSettingsGetId,
  getLinks: _appSettingsGetLinks,
  attach: _appSettingsAttach,
  version: '3.3.2',
);

int _appSettingsEstimateSize(
  AppSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.selectedTfliteModel.length * 3;
  bytesCount += 3 + object.tfmServerApiKey.length * 3;
  bytesCount += 3 + object.tfmServerScheme.length * 3;
  bytesCount += 3 + object.tfmServerUrl.length * 3;
  bytesCount += 3 + object.themeMode.length * 3;
  return bytesCount;
}

void _appSettingsSerialize(
  AppSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.agronomicDayEnd);
  writer.writeLong(offsets[1], object.agronomicDayStart);
  writer.writeBool(offsets[2], object.alwaysForceInference);
  writer.writeDouble(offsets[3], object.gpsLat);
  writer.writeDouble(offsets[4], object.gpsLon);
  writer.writeBool(offsets[5], object.invertModelOutput);
  writer.writeBool(offsets[6], object.isFirstTime);
  writer.writeBool(offsets[7], object.isGpsEnabled);
  writer.writeDouble(offsets[8], object.manualLat);
  writer.writeDouble(offsets[9], object.manualLon);
  writer.writeDouble(offsets[10], object.minHumidity);
  writer.writeBool(offsets[11], object.permitOpenMeteoFill);
  writer.writeString(offsets[12], object.selectedTfliteModel);
  writer.writeLong(offsets[13], object.syncScheduleHours);
  writer.writeString(offsets[14], object.tfmServerApiKey);
  writer.writeLong(offsets[15], object.tfmServerPort);
  writer.writeString(offsets[16], object.tfmServerScheme);
  writer.writeString(offsets[17], object.tfmServerUrl);
  writer.writeString(offsets[18], object.themeMode);
}

AppSettings _appSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettings();
  object.agronomicDayEnd = reader.readLong(offsets[0]);
  object.agronomicDayStart = reader.readLong(offsets[1]);
  object.alwaysForceInference = reader.readBool(offsets[2]);
  object.gpsLat = reader.readDouble(offsets[3]);
  object.gpsLon = reader.readDouble(offsets[4]);
  object.id = id;
  object.invertModelOutput = reader.readBool(offsets[5]);
  object.isFirstTime = reader.readBool(offsets[6]);
  object.isGpsEnabled = reader.readBool(offsets[7]);
  object.manualLat = reader.readDouble(offsets[8]);
  object.manualLon = reader.readDouble(offsets[9]);
  object.minHumidity = reader.readDouble(offsets[10]);
  object.permitOpenMeteoFill = reader.readBool(offsets[11]);
  object.selectedTfliteModel = reader.readString(offsets[12]);
  object.syncScheduleHours = reader.readLong(offsets[13]);
  object.tfmServerApiKey = reader.readString(offsets[14]);
  object.tfmServerPort = reader.readLong(offsets[15]);
  object.tfmServerScheme = reader.readString(offsets[16]);
  object.tfmServerUrl = reader.readString(offsets[17]);
  object.themeMode = reader.readString(offsets[18]);
  return object;
}

P _appSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsGetId(AppSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSettingsGetLinks(AppSettings object) {
  return [];
}

void _appSettingsAttach(
  IsarCollection<dynamic> col,
  Id id,
  AppSettings object,
) {
  object.id = id;
}

extension AppSettingsQueryWhereSort
    on QueryBuilder<AppSettings, AppSettings, QWhere> {
  QueryBuilder<AppSettings, AppSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsQueryWhere
    on QueryBuilder<AppSettings, AppSettings, QWhereClause> {
  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idBetween(
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
}

extension AppSettingsQueryFilter
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {
  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayEndEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'agronomicDayEnd', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayEndGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'agronomicDayEnd',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayEndLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'agronomicDayEnd',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayEndBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'agronomicDayEnd',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayStartEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'agronomicDayStart', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayStartGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'agronomicDayStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayStartLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'agronomicDayStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  agronomicDayStartBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'agronomicDayStart',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  alwaysForceInferenceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'alwaysForceInference',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gpsLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  gpsLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gpsLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gpsLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gpsLat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLonEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gpsLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  gpsLonGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gpsLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLonLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gpsLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> gpsLonBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gpsLon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  invertModelOutputEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'invertModelOutput', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  isFirstTimeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFirstTime', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  isGpsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isGpsEnabled', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLatEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manualLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manualLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manualLat',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manualLat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLonEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manualLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLonGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manualLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLonLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manualLon',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  manualLonBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manualLon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  minHumidityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'minHumidity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  minHumidityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'minHumidity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  minHumidityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'minHumidity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  minHumidityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'minHumidity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  permitOpenMeteoFillEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'permitOpenMeteoFill', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedTfliteModel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'selectedTfliteModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'selectedTfliteModel',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectedTfliteModel', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  selectedTfliteModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'selectedTfliteModel',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  syncScheduleHoursEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncScheduleHours', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  syncScheduleHoursGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncScheduleHours',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  syncScheduleHoursLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncScheduleHours',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  syncScheduleHoursBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncScheduleHours',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tfmServerApiKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tfmServerApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tfmServerApiKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tfmServerApiKey', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerApiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tfmServerApiKey', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerPortEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tfmServerPort', value: value),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerPortGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tfmServerPort',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerPortLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tfmServerPort',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerPortBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tfmServerPort',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tfmServerScheme',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tfmServerScheme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tfmServerScheme',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tfmServerScheme', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerSchemeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tfmServerScheme', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tfmServerUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tfmServerUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tfmServerUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tfmServerUrl', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  tfmServerUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tfmServerUrl', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'themeMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'themeMode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'themeMode', value: ''),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
  themeModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'themeMode', value: ''),
      );
    });
  }
}

extension AppSettingsQueryObject
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {}

extension AppSettingsQueryLinks
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {}

extension AppSettingsQuerySortBy
    on QueryBuilder<AppSettings, AppSettings, QSortBy> {
  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByAgronomicDayEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayEnd', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByAgronomicDayEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayEnd', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByAgronomicDayStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayStart', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByAgronomicDayStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayStart', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByAlwaysForceInference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alwaysForceInference', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByAlwaysForceInferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alwaysForceInference', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByGpsLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLat', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByGpsLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLat', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByGpsLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLon', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByGpsLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLon', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByInvertModelOutput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invertModelOutput', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByInvertModelOutputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invertModelOutput', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByIsFirstTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFirstTime', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByIsFirstTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFirstTime', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByIsGpsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGpsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByIsGpsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGpsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByManualLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLat', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByManualLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLat', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByManualLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLon', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByManualLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLon', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByMinHumidity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minHumidity', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByMinHumidityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minHumidity', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByPermitOpenMeteoFill() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permitOpenMeteoFill', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByPermitOpenMeteoFillDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permitOpenMeteoFill', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortBySelectedTfliteModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedTfliteModel', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortBySelectedTfliteModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedTfliteModel', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortBySyncScheduleHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncScheduleHours', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortBySyncScheduleHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncScheduleHours', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTfmServerApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerApiKey', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByTfmServerApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerApiKey', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTfmServerPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerPort', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByTfmServerPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerPort', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTfmServerScheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerScheme', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByTfmServerSchemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerScheme', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTfmServerUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  sortByTfmServerUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }
}

extension AppSettingsQuerySortThenBy
    on QueryBuilder<AppSettings, AppSettings, QSortThenBy> {
  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByAgronomicDayEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayEnd', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByAgronomicDayEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayEnd', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByAgronomicDayStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayStart', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByAgronomicDayStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agronomicDayStart', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByAlwaysForceInference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alwaysForceInference', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByAlwaysForceInferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alwaysForceInference', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByGpsLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLat', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByGpsLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLat', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByGpsLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLon', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByGpsLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsLon', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByInvertModelOutput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invertModelOutput', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByInvertModelOutputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invertModelOutput', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByIsFirstTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFirstTime', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByIsFirstTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFirstTime', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByIsGpsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGpsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByIsGpsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGpsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByManualLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLat', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByManualLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLat', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByManualLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLon', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByManualLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualLon', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByMinHumidity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minHumidity', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByMinHumidityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minHumidity', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByPermitOpenMeteoFill() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permitOpenMeteoFill', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByPermitOpenMeteoFillDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permitOpenMeteoFill', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenBySelectedTfliteModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedTfliteModel', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenBySelectedTfliteModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedTfliteModel', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenBySyncScheduleHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncScheduleHours', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenBySyncScheduleHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncScheduleHours', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTfmServerApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerApiKey', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByTfmServerApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerApiKey', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTfmServerPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerPort', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByTfmServerPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerPort', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTfmServerScheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerScheme', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByTfmServerSchemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerScheme', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTfmServerUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
  thenByTfmServerUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tfmServerUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }
}

extension AppSettingsQueryWhereDistinct
    on QueryBuilder<AppSettings, AppSettings, QDistinct> {
  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctByAgronomicDayEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'agronomicDayEnd');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctByAgronomicDayStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'agronomicDayStart');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctByAlwaysForceInference() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alwaysForceInference');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByGpsLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gpsLat');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByGpsLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gpsLon');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctByInvertModelOutput() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invertModelOutput');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByIsFirstTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFirstTime');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByIsGpsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGpsEnabled');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByManualLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manualLat');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByManualLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manualLon');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByMinHumidity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minHumidity');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctByPermitOpenMeteoFill() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'permitOpenMeteoFill');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctBySelectedTfliteModel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'selectedTfliteModel',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
  distinctBySyncScheduleHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncScheduleHours');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByTfmServerApiKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'tfmServerApiKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByTfmServerPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tfmServerPort');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByTfmServerScheme({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'tfmServerScheme',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByTfmServerUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tfmServerUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByThemeMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeMode', caseSensitive: caseSensitive);
    });
  }
}

extension AppSettingsQueryProperty
    on QueryBuilder<AppSettings, AppSettings, QQueryProperty> {
  QueryBuilder<AppSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettings, int, QQueryOperations> agronomicDayEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'agronomicDayEnd');
    });
  }

  QueryBuilder<AppSettings, int, QQueryOperations> agronomicDayStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'agronomicDayStart');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations>
  alwaysForceInferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alwaysForceInference');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> gpsLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gpsLat');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> gpsLonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gpsLon');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations>
  invertModelOutputProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invertModelOutput');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations> isFirstTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFirstTime');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations> isGpsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGpsEnabled');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> manualLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualLat');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> manualLonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualLon');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> minHumidityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minHumidity');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations>
  permitOpenMeteoFillProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'permitOpenMeteoFill');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
  selectedTfliteModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedTfliteModel');
    });
  }

  QueryBuilder<AppSettings, int, QQueryOperations> syncScheduleHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncScheduleHours');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
  tfmServerApiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tfmServerApiKey');
    });
  }

  QueryBuilder<AppSettings, int, QQueryOperations> tfmServerPortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tfmServerPort');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
  tfmServerSchemeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tfmServerScheme');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> tfmServerUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tfmServerUrl');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> themeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeMode');
    });
  }
}
