// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_file_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRateFileAnalysisIsarCollection on Isar {
  IsarCollection<RateFileAnalysisIsar> get rateFileAnalysisIsars =>
      this.collection();
}

const RateFileAnalysisIsarSchema = CollectionSchema(
  name: r'RateFileAnalysisIsar',
  id: 2709277375428934399,
  properties: {
    r'detectedFieldsJson': PropertySchema(
      id: 0,
      name: r'detectedFieldsJson',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 1,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'rateFileId': PropertySchema(
      id: 2,
      name: r'rateFileId',
      type: IsarType.string,
    ),
    r'siteId': PropertySchema(
      id: 3,
      name: r'siteId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 4,
      name: r'status',
      type: IsarType.string,
    ),
    r'syncedAt': PropertySchema(
      id: 5,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'uploadDate': PropertySchema(
      id: 6,
      name: r'uploadDate',
      type: IsarType.string,
    )
  },
  estimateSize: _rateFileAnalysisIsarEstimateSize,
  serialize: _rateFileAnalysisIsarSerialize,
  deserialize: _rateFileAnalysisIsarDeserialize,
  deserializeProp: _rateFileAnalysisIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'rateFileId': IndexSchema(
      id: -3018785114056852661,
      name: r'rateFileId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'rateFileId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'siteId': IndexSchema(
      id: -4500477726541977412,
      name: r'siteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'siteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _rateFileAnalysisIsarGetId,
  getLinks: _rateFileAnalysisIsarGetLinks,
  attach: _rateFileAnalysisIsarAttach,
  version: '3.3.0',
);

int _rateFileAnalysisIsarEstimateSize(
  RateFileAnalysisIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.detectedFieldsJson.length * 3;
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.rateFileId.length * 3;
  bytesCount += 3 + object.siteId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.uploadDate.length * 3;
  return bytesCount;
}

void _rateFileAnalysisIsarSerialize(
  RateFileAnalysisIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.detectedFieldsJson);
  writer.writeString(offsets[1], object.fileName);
  writer.writeString(offsets[2], object.rateFileId);
  writer.writeString(offsets[3], object.siteId);
  writer.writeString(offsets[4], object.status);
  writer.writeDateTime(offsets[5], object.syncedAt);
  writer.writeString(offsets[6], object.uploadDate);
}

RateFileAnalysisIsar _rateFileAnalysisIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RateFileAnalysisIsar();
  object.detectedFieldsJson = reader.readString(offsets[0]);
  object.fileName = reader.readString(offsets[1]);
  object.isarId = id;
  object.rateFileId = reader.readString(offsets[2]);
  object.siteId = reader.readString(offsets[3]);
  object.status = reader.readString(offsets[4]);
  object.syncedAt = reader.readDateTime(offsets[5]);
  object.uploadDate = reader.readString(offsets[6]);
  return object;
}

P _rateFileAnalysisIsarDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rateFileAnalysisIsarGetId(RateFileAnalysisIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _rateFileAnalysisIsarGetLinks(
    RateFileAnalysisIsar object) {
  return [];
}

void _rateFileAnalysisIsarAttach(
    IsarCollection<dynamic> col, Id id, RateFileAnalysisIsar object) {
  object.isarId = id;
}

extension RateFileAnalysisIsarByIndex on IsarCollection<RateFileAnalysisIsar> {
  Future<RateFileAnalysisIsar?> getByRateFileId(String rateFileId) {
    return getByIndex(r'rateFileId', [rateFileId]);
  }

  RateFileAnalysisIsar? getByRateFileIdSync(String rateFileId) {
    return getByIndexSync(r'rateFileId', [rateFileId]);
  }

  Future<bool> deleteByRateFileId(String rateFileId) {
    return deleteByIndex(r'rateFileId', [rateFileId]);
  }

  bool deleteByRateFileIdSync(String rateFileId) {
    return deleteByIndexSync(r'rateFileId', [rateFileId]);
  }

  Future<List<RateFileAnalysisIsar?>> getAllByRateFileId(
      List<String> rateFileIdValues) {
    final values = rateFileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'rateFileId', values);
  }

  List<RateFileAnalysisIsar?> getAllByRateFileIdSync(
      List<String> rateFileIdValues) {
    final values = rateFileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'rateFileId', values);
  }

  Future<int> deleteAllByRateFileId(List<String> rateFileIdValues) {
    final values = rateFileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'rateFileId', values);
  }

  int deleteAllByRateFileIdSync(List<String> rateFileIdValues) {
    final values = rateFileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'rateFileId', values);
  }

  Future<Id> putByRateFileId(RateFileAnalysisIsar object) {
    return putByIndex(r'rateFileId', object);
  }

  Id putByRateFileIdSync(RateFileAnalysisIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'rateFileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRateFileId(List<RateFileAnalysisIsar> objects) {
    return putAllByIndex(r'rateFileId', objects);
  }

  List<Id> putAllByRateFileIdSync(List<RateFileAnalysisIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'rateFileId', objects, saveLinks: saveLinks);
  }
}

extension RateFileAnalysisIsarQueryWhereSort
    on QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QWhere> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RateFileAnalysisIsarQueryWhere
    on QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QWhereClause> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      rateFileIdEqualTo(String rateFileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rateFileId',
        value: [rateFileId],
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      rateFileIdNotEqualTo(String rateFileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [],
              upper: [rateFileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [rateFileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [rateFileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [],
              upper: [rateFileId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      siteIdEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'siteId',
        value: [siteId],
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterWhereClause>
      siteIdNotEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RateFileAnalysisIsarQueryFilter on QueryBuilder<RateFileAnalysisIsar,
    RateFileAnalysisIsar, QFilterCondition> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedFieldsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      detectedFieldsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'detectedFieldsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      detectedFieldsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'detectedFieldsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedFieldsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> detectedFieldsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'detectedFieldsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateFileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      rateFileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      rateFileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateFileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateFileId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> rateFileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateFileId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'siteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      siteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      siteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> siteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> syncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> syncedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> syncedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> syncedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      uploadDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uploadDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
          QAfterFilterCondition>
      uploadDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uploadDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadDate',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar,
      QAfterFilterCondition> uploadDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uploadDate',
        value: '',
      ));
    });
  }
}

extension RateFileAnalysisIsarQueryObject on QueryBuilder<RateFileAnalysisIsar,
    RateFileAnalysisIsar, QFilterCondition> {}

extension RateFileAnalysisIsarQueryLinks on QueryBuilder<RateFileAnalysisIsar,
    RateFileAnalysisIsar, QFilterCondition> {}

extension RateFileAnalysisIsarQuerySortBy
    on QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QSortBy> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByDetectedFieldsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedFieldsJson', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByDetectedFieldsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedFieldsJson', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByRateFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByRateFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByUploadDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadDate', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      sortByUploadDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadDate', Sort.desc);
    });
  }
}

extension RateFileAnalysisIsarQuerySortThenBy
    on QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QSortThenBy> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByDetectedFieldsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedFieldsJson', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByDetectedFieldsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedFieldsJson', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByRateFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByRateFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByUploadDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadDate', Sort.asc);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QAfterSortBy>
      thenByUploadDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadDate', Sort.desc);
    });
  }
}

extension RateFileAnalysisIsarQueryWhereDistinct
    on QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct> {
  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctByDetectedFieldsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedFieldsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctByRateFileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateFileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctBySiteId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, RateFileAnalysisIsar, QDistinct>
      distinctByUploadDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadDate', caseSensitive: caseSensitive);
    });
  }
}

extension RateFileAnalysisIsarQueryProperty on QueryBuilder<
    RateFileAnalysisIsar, RateFileAnalysisIsar, QQueryProperty> {
  QueryBuilder<RateFileAnalysisIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      detectedFieldsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedFieldsJson');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      rateFileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateFileId');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      siteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteId');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, DateTime, QQueryOperations>
      syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<RateFileAnalysisIsar, String, QQueryOperations>
      uploadDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadDate');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRateFileMaterialIsarCollection on Isar {
  IsarCollection<RateFileMaterialIsar> get rateFileMaterialIsars =>
      this.collection();
}

const RateFileMaterialIsarSchema = CollectionSchema(
  name: r'RateFileMaterialIsar',
  id: -8632564182947203163,
  properties: {
    r'approvalStatus': PropertySchema(
      id: 0,
      name: r'approvalStatus',
      type: IsarType.string,
    ),
    r'calculationCategory': PropertySchema(
      id: 1,
      name: r'calculationCategory',
      type: IsarType.string,
    ),
    r'designationJoined': PropertySchema(
      id: 2,
      name: r'designationJoined',
      type: IsarType.string,
    ),
    r'displayOrder': PropertySchema(
      id: 3,
      name: r'displayOrder',
      type: IsarType.long,
    ),
    r'dynamicFields': PropertySchema(
      id: 4,
      name: r'dynamicFields',
      type: IsarType.objectList,
      target: r'DynamicFieldIsar',
    ),
    r'image': PropertySchema(
      id: 5,
      name: r'image',
      type: IsarType.string,
    ),
    r'materialId': PropertySchema(
      id: 6,
      name: r'materialId',
      type: IsarType.string,
    ),
    r'materialName': PropertySchema(
      id: 7,
      name: r'materialName',
      type: IsarType.string,
    ),
    r'normalizedMaterialName': PropertySchema(
      id: 8,
      name: r'normalizedMaterialName',
      type: IsarType.string,
    ),
    r'normalizedMoc': PropertySchema(
      id: 9,
      name: r'normalizedMoc',
      type: IsarType.string,
    ),
    r'rateFileId': PropertySchema(
      id: 10,
      name: r'rateFileId',
      type: IsarType.string,
    ),
    r'rawMaterialName': PropertySchema(
      id: 11,
      name: r'rawMaterialName',
      type: IsarType.string,
    ),
    r'siteId': PropertySchema(
      id: 12,
      name: r'siteId',
      type: IsarType.string,
    ),
    r'uom': PropertySchema(
      id: 13,
      name: r'uom',
      type: IsarType.string,
    )
  },
  estimateSize: _rateFileMaterialIsarEstimateSize,
  serialize: _rateFileMaterialIsarSerialize,
  deserialize: _rateFileMaterialIsarDeserialize,
  deserializeProp: _rateFileMaterialIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'materialId': IndexSchema(
      id: -4039490305560314015,
      name: r'materialId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'materialId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'siteId': IndexSchema(
      id: -4500477726541977412,
      name: r'siteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'siteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'rateFileId': IndexSchema(
      id: -3018785114056852661,
      name: r'rateFileId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rateFileId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'DynamicFieldIsar': DynamicFieldIsarSchema},
  getId: _rateFileMaterialIsarGetId,
  getLinks: _rateFileMaterialIsarGetLinks,
  attach: _rateFileMaterialIsarAttach,
  version: '3.3.0',
);

int _rateFileMaterialIsarEstimateSize(
  RateFileMaterialIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.approvalStatus.length * 3;
  bytesCount += 3 + object.calculationCategory.length * 3;
  bytesCount += 3 + object.designationJoined.length * 3;
  bytesCount += 3 + object.dynamicFields.length * 3;
  {
    final offsets = allOffsets[DynamicFieldIsar]!;
    for (var i = 0; i < object.dynamicFields.length; i++) {
      final value = object.dynamicFields[i];
      bytesCount +=
          DynamicFieldIsarSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.image.length * 3;
  bytesCount += 3 + object.materialId.length * 3;
  bytesCount += 3 + object.materialName.length * 3;
  bytesCount += 3 + object.normalizedMaterialName.length * 3;
  bytesCount += 3 + object.normalizedMoc.length * 3;
  bytesCount += 3 + object.rateFileId.length * 3;
  bytesCount += 3 + object.rawMaterialName.length * 3;
  bytesCount += 3 + object.siteId.length * 3;
  bytesCount += 3 + object.uom.length * 3;
  return bytesCount;
}

void _rateFileMaterialIsarSerialize(
  RateFileMaterialIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.approvalStatus);
  writer.writeString(offsets[1], object.calculationCategory);
  writer.writeString(offsets[2], object.designationJoined);
  writer.writeLong(offsets[3], object.displayOrder);
  writer.writeObjectList<DynamicFieldIsar>(
    offsets[4],
    allOffsets,
    DynamicFieldIsarSchema.serialize,
    object.dynamicFields,
  );
  writer.writeString(offsets[5], object.image);
  writer.writeString(offsets[6], object.materialId);
  writer.writeString(offsets[7], object.materialName);
  writer.writeString(offsets[8], object.normalizedMaterialName);
  writer.writeString(offsets[9], object.normalizedMoc);
  writer.writeString(offsets[10], object.rateFileId);
  writer.writeString(offsets[11], object.rawMaterialName);
  writer.writeString(offsets[12], object.siteId);
  writer.writeString(offsets[13], object.uom);
}

RateFileMaterialIsar _rateFileMaterialIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RateFileMaterialIsar();
  object.approvalStatus = reader.readString(offsets[0]);
  object.calculationCategory = reader.readString(offsets[1]);
  object.designationJoined = reader.readString(offsets[2]);
  object.displayOrder = reader.readLong(offsets[3]);
  object.dynamicFields = reader.readObjectList<DynamicFieldIsar>(
        offsets[4],
        DynamicFieldIsarSchema.deserialize,
        allOffsets,
        DynamicFieldIsar(),
      ) ??
      [];
  object.image = reader.readString(offsets[5]);
  object.isarId = id;
  object.materialId = reader.readString(offsets[6]);
  object.materialName = reader.readString(offsets[7]);
  object.normalizedMaterialName = reader.readString(offsets[8]);
  object.normalizedMoc = reader.readString(offsets[9]);
  object.rateFileId = reader.readString(offsets[10]);
  object.rawMaterialName = reader.readString(offsets[11]);
  object.siteId = reader.readString(offsets[12]);
  object.uom = reader.readString(offsets[13]);
  return object;
}

P _rateFileMaterialIsarDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readObjectList<DynamicFieldIsar>(
            offset,
            DynamicFieldIsarSchema.deserialize,
            allOffsets,
            DynamicFieldIsar(),
          ) ??
          []) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rateFileMaterialIsarGetId(RateFileMaterialIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _rateFileMaterialIsarGetLinks(
    RateFileMaterialIsar object) {
  return [];
}

void _rateFileMaterialIsarAttach(
    IsarCollection<dynamic> col, Id id, RateFileMaterialIsar object) {
  object.isarId = id;
}

extension RateFileMaterialIsarByIndex on IsarCollection<RateFileMaterialIsar> {
  Future<RateFileMaterialIsar?> getByMaterialId(String materialId) {
    return getByIndex(r'materialId', [materialId]);
  }

  RateFileMaterialIsar? getByMaterialIdSync(String materialId) {
    return getByIndexSync(r'materialId', [materialId]);
  }

  Future<bool> deleteByMaterialId(String materialId) {
    return deleteByIndex(r'materialId', [materialId]);
  }

  bool deleteByMaterialIdSync(String materialId) {
    return deleteByIndexSync(r'materialId', [materialId]);
  }

  Future<List<RateFileMaterialIsar?>> getAllByMaterialId(
      List<String> materialIdValues) {
    final values = materialIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'materialId', values);
  }

  List<RateFileMaterialIsar?> getAllByMaterialIdSync(
      List<String> materialIdValues) {
    final values = materialIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'materialId', values);
  }

  Future<int> deleteAllByMaterialId(List<String> materialIdValues) {
    final values = materialIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'materialId', values);
  }

  int deleteAllByMaterialIdSync(List<String> materialIdValues) {
    final values = materialIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'materialId', values);
  }

  Future<Id> putByMaterialId(RateFileMaterialIsar object) {
    return putByIndex(r'materialId', object);
  }

  Id putByMaterialIdSync(RateFileMaterialIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'materialId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMaterialId(List<RateFileMaterialIsar> objects) {
    return putAllByIndex(r'materialId', objects);
  }

  List<Id> putAllByMaterialIdSync(List<RateFileMaterialIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'materialId', objects, saveLinks: saveLinks);
  }
}

extension RateFileMaterialIsarQueryWhereSort
    on QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QWhere> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RateFileMaterialIsarQueryWhere
    on QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QWhereClause> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      materialIdEqualTo(String materialId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'materialId',
        value: [materialId],
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      materialIdNotEqualTo(String materialId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [],
              upper: [materialId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [materialId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [materialId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [],
              upper: [materialId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      siteIdEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'siteId',
        value: [siteId],
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      siteIdNotEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      rateFileIdEqualTo(String rateFileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rateFileId',
        value: [rateFileId],
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterWhereClause>
      rateFileIdNotEqualTo(String rateFileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [],
              upper: [rateFileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [rateFileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [rateFileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rateFileId',
              lower: [],
              upper: [rateFileId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RateFileMaterialIsarQueryFilter on QueryBuilder<RateFileMaterialIsar,
    RateFileMaterialIsar, QFilterCondition> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'approvalStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      approvalStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'approvalStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      approvalStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'approvalStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvalStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> approvalStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'approvalStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calculationCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      calculationCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'calculationCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      calculationCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'calculationCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calculationCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> calculationCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'calculationCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'designationJoined',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      designationJoinedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'designationJoined',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      designationJoinedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'designationJoined',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'designationJoined',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> designationJoinedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'designationJoined',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> displayOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> displayOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> displayOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> displayOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> dynamicFieldsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dynamicFields',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'image',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      imageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      imageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'image',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'materialId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      materialIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      materialIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'materialId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'materialId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'materialName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      materialNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'materialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      materialNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'materialName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> materialNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'materialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedMaterialName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      normalizedMaterialNameContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      normalizedMaterialNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedMaterialName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedMaterialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMaterialNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedMaterialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedMoc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      normalizedMocContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedMoc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      normalizedMocMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedMoc',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedMoc',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> normalizedMocIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedMoc',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateFileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      rateFileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateFileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      rateFileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateFileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateFileId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rateFileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateFileId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rawMaterialName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      rawMaterialNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rawMaterialName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      rawMaterialNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rawMaterialName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawMaterialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> rawMaterialNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rawMaterialName',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'siteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      siteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      siteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> siteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      uomContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      uomMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uom',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uom',
        value: '',
      ));
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
      QAfterFilterCondition> uomIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uom',
        value: '',
      ));
    });
  }
}

extension RateFileMaterialIsarQueryObject on QueryBuilder<RateFileMaterialIsar,
    RateFileMaterialIsar, QFilterCondition> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar,
          QAfterFilterCondition>
      dynamicFieldsElement(FilterQuery<DynamicFieldIsar> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'dynamicFields');
    });
  }
}

extension RateFileMaterialIsarQueryLinks on QueryBuilder<RateFileMaterialIsar,
    RateFileMaterialIsar, QFilterCondition> {}

extension RateFileMaterialIsarQuerySortBy
    on QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QSortBy> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByApprovalStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvalStatus', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByApprovalStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvalStatus', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByCalculationCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calculationCategory', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByCalculationCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calculationCategory', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByDesignationJoined() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designationJoined', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByDesignationJoinedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designationJoined', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByDisplayOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayOrder', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByDisplayOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayOrder', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByMaterialId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByMaterialIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByNormalizedMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMaterialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByNormalizedMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMaterialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByNormalizedMoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMoc', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByNormalizedMocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMoc', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByRateFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByRateFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByRawMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMaterialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByRawMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMaterialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByUom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      sortByUomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.desc);
    });
  }
}

extension RateFileMaterialIsarQuerySortThenBy
    on QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QSortThenBy> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByApprovalStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvalStatus', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByApprovalStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvalStatus', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByCalculationCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calculationCategory', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByCalculationCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calculationCategory', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByDesignationJoined() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designationJoined', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByDesignationJoinedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designationJoined', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByDisplayOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayOrder', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByDisplayOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayOrder', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByMaterialId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByMaterialIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByNormalizedMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMaterialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByNormalizedMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMaterialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByNormalizedMoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMoc', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByNormalizedMocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedMoc', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByRateFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByRateFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateFileId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByRawMaterialName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMaterialName', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByRawMaterialNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMaterialName', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByUom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.asc);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QAfterSortBy>
      thenByUomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.desc);
    });
  }
}

extension RateFileMaterialIsarQueryWhereDistinct
    on QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct> {
  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByApprovalStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'approvalStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByCalculationCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calculationCategory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByDesignationJoined({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'designationJoined',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByDisplayOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayOrder');
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByImage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByMaterialId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'materialId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByMaterialName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'materialName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByNormalizedMaterialName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedMaterialName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByNormalizedMoc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedMoc',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByRateFileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateFileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByRawMaterialName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawMaterialName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctBySiteId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateFileMaterialIsar, RateFileMaterialIsar, QDistinct>
      distinctByUom({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uom', caseSensitive: caseSensitive);
    });
  }
}

extension RateFileMaterialIsarQueryProperty on QueryBuilder<
    RateFileMaterialIsar, RateFileMaterialIsar, QQueryProperty> {
  QueryBuilder<RateFileMaterialIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      approvalStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'approvalStatus');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      calculationCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calculationCategory');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      designationJoinedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'designationJoined');
    });
  }

  QueryBuilder<RateFileMaterialIsar, int, QQueryOperations>
      displayOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayOrder');
    });
  }

  QueryBuilder<RateFileMaterialIsar, List<DynamicFieldIsar>, QQueryOperations>
      dynamicFieldsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dynamicFields');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations> imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      materialIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'materialId');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      materialNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'materialName');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      normalizedMaterialNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedMaterialName');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      normalizedMocProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedMoc');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      rateFileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateFileId');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      rawMaterialNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawMaterialName');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations>
      siteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteId');
    });
  }

  QueryBuilder<RateFileMaterialIsar, String, QQueryOperations> uomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uom');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRateVariantIsarCollection on Isar {
  IsarCollection<RateVariantIsar> get rateVariantIsars => this.collection();
}

const RateVariantIsarSchema = CollectionSchema(
  name: r'RateVariantIsar',
  id: 1133665798697969612,
  properties: {
    r'floor': PropertySchema(
      id: 0,
      name: r'floor',
      type: IsarType.string,
    ),
    r'materialId': PropertySchema(
      id: 1,
      name: r'materialId',
      type: IsarType.string,
    ),
    r'moc': PropertySchema(
      id: 2,
      name: r'moc',
      type: IsarType.string,
    ),
    r'rate': PropertySchema(
      id: 3,
      name: r'rate',
      type: IsarType.double,
    ),
    r'remarks': PropertySchema(
      id: 4,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'siteId': PropertySchema(
      id: 5,
      name: r'siteId',
      type: IsarType.string,
    ),
    r'uom': PropertySchema(
      id: 6,
      name: r'uom',
      type: IsarType.string,
    ),
    r'variantKey': PropertySchema(
      id: 7,
      name: r'variantKey',
      type: IsarType.string,
    )
  },
  estimateSize: _rateVariantIsarEstimateSize,
  serialize: _rateVariantIsarSerialize,
  deserialize: _rateVariantIsarDeserialize,
  deserializeProp: _rateVariantIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'variantKey': IndexSchema(
      id: 2917806305668948475,
      name: r'variantKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'variantKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'siteId': IndexSchema(
      id: -4500477726541977412,
      name: r'siteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'siteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'materialId': IndexSchema(
      id: -4039490305560314015,
      name: r'materialId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'materialId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _rateVariantIsarGetId,
  getLinks: _rateVariantIsarGetLinks,
  attach: _rateVariantIsarAttach,
  version: '3.3.0',
);

int _rateVariantIsarEstimateSize(
  RateVariantIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.floor.length * 3;
  bytesCount += 3 + object.materialId.length * 3;
  bytesCount += 3 + object.moc.length * 3;
  bytesCount += 3 + object.remarks.length * 3;
  bytesCount += 3 + object.siteId.length * 3;
  bytesCount += 3 + object.uom.length * 3;
  bytesCount += 3 + object.variantKey.length * 3;
  return bytesCount;
}

void _rateVariantIsarSerialize(
  RateVariantIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.floor);
  writer.writeString(offsets[1], object.materialId);
  writer.writeString(offsets[2], object.moc);
  writer.writeDouble(offsets[3], object.rate);
  writer.writeString(offsets[4], object.remarks);
  writer.writeString(offsets[5], object.siteId);
  writer.writeString(offsets[6], object.uom);
  writer.writeString(offsets[7], object.variantKey);
}

RateVariantIsar _rateVariantIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RateVariantIsar();
  object.floor = reader.readString(offsets[0]);
  object.isarId = id;
  object.materialId = reader.readString(offsets[1]);
  object.moc = reader.readString(offsets[2]);
  object.rate = reader.readDouble(offsets[3]);
  object.remarks = reader.readString(offsets[4]);
  object.siteId = reader.readString(offsets[5]);
  object.uom = reader.readString(offsets[6]);
  object.variantKey = reader.readString(offsets[7]);
  return object;
}

P _rateVariantIsarDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rateVariantIsarGetId(RateVariantIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _rateVariantIsarGetLinks(RateVariantIsar object) {
  return [];
}

void _rateVariantIsarAttach(
    IsarCollection<dynamic> col, Id id, RateVariantIsar object) {
  object.isarId = id;
}

extension RateVariantIsarByIndex on IsarCollection<RateVariantIsar> {
  Future<RateVariantIsar?> getByVariantKey(String variantKey) {
    return getByIndex(r'variantKey', [variantKey]);
  }

  RateVariantIsar? getByVariantKeySync(String variantKey) {
    return getByIndexSync(r'variantKey', [variantKey]);
  }

  Future<bool> deleteByVariantKey(String variantKey) {
    return deleteByIndex(r'variantKey', [variantKey]);
  }

  bool deleteByVariantKeySync(String variantKey) {
    return deleteByIndexSync(r'variantKey', [variantKey]);
  }

  Future<List<RateVariantIsar?>> getAllByVariantKey(
      List<String> variantKeyValues) {
    final values = variantKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'variantKey', values);
  }

  List<RateVariantIsar?> getAllByVariantKeySync(List<String> variantKeyValues) {
    final values = variantKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'variantKey', values);
  }

  Future<int> deleteAllByVariantKey(List<String> variantKeyValues) {
    final values = variantKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'variantKey', values);
  }

  int deleteAllByVariantKeySync(List<String> variantKeyValues) {
    final values = variantKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'variantKey', values);
  }

  Future<Id> putByVariantKey(RateVariantIsar object) {
    return putByIndex(r'variantKey', object);
  }

  Id putByVariantKeySync(RateVariantIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'variantKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVariantKey(List<RateVariantIsar> objects) {
    return putAllByIndex(r'variantKey', objects);
  }

  List<Id> putAllByVariantKeySync(List<RateVariantIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'variantKey', objects, saveLinks: saveLinks);
  }
}

extension RateVariantIsarQueryWhereSort
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QWhere> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RateVariantIsarQueryWhere
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QWhereClause> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      variantKeyEqualTo(String variantKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'variantKey',
        value: [variantKey],
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      variantKeyNotEqualTo(String variantKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'variantKey',
              lower: [],
              upper: [variantKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'variantKey',
              lower: [variantKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'variantKey',
              lower: [variantKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'variantKey',
              lower: [],
              upper: [variantKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      siteIdEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'siteId',
        value: [siteId],
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      siteIdNotEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [siteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'siteId',
              lower: [],
              upper: [siteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      materialIdEqualTo(String materialId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'materialId',
        value: [materialId],
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterWhereClause>
      materialIdNotEqualTo(String materialId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [],
              upper: [materialId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [materialId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [materialId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'materialId',
              lower: [],
              upper: [materialId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RateVariantIsarQueryFilter
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QFilterCondition> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'floor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'floor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'floor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'floor',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      floorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'floor',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'materialId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'materialId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'materialId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'materialId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      materialIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'materialId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'moc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'moc',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moc',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      mocIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'moc',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      rateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      rateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      rateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      rateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'siteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      siteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uom',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uom',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      uomIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uom',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'variantKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'variantKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'variantKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'variantKey',
        value: '',
      ));
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterFilterCondition>
      variantKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'variantKey',
        value: '',
      ));
    });
  }
}

extension RateVariantIsarQueryObject
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QFilterCondition> {}

extension RateVariantIsarQueryLinks
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QFilterCondition> {}

extension RateVariantIsarQuerySortBy
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QSortBy> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByFloor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floor', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByFloorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floor', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByMaterialId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByMaterialIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByMoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moc', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByMocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moc', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByUom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> sortByUomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByVariantKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variantKey', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      sortByVariantKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variantKey', Sort.desc);
    });
  }
}

extension RateVariantIsarQuerySortThenBy
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QSortThenBy> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByFloor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floor', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByFloorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floor', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByMaterialId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByMaterialIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'materialId', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByMoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moc', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByMocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moc', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByUom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy> thenByUomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uom', Sort.desc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByVariantKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variantKey', Sort.asc);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QAfterSortBy>
      thenByVariantKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variantKey', Sort.desc);
    });
  }
}

extension RateVariantIsarQueryWhereDistinct
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> {
  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctByFloor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'floor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct>
      distinctByMaterialId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'materialId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctByMoc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moc', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rate');
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctBySiteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct> distinctByUom(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uom', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RateVariantIsar, RateVariantIsar, QDistinct>
      distinctByVariantKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'variantKey', caseSensitive: caseSensitive);
    });
  }
}

extension RateVariantIsarQueryProperty
    on QueryBuilder<RateVariantIsar, RateVariantIsar, QQueryProperty> {
  QueryBuilder<RateVariantIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> floorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'floor');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> materialIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'materialId');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> mocProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moc');
    });
  }

  QueryBuilder<RateVariantIsar, double, QQueryOperations> rateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rate');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> siteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteId');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> uomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uom');
    });
  }

  QueryBuilder<RateVariantIsar, String, QQueryOperations> variantKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'variantKey');
    });
  }
}
