// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boq_structure_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBOQStructureIsarCollection on Isar {
  IsarCollection<BOQStructureIsar> get bOQStructureIsars => this.collection();
}

const BOQStructureIsarSchema = CollectionSchema(
  name: r'BOQStructureIsar',
  id: -4978109616325680663,
  properties: {
    r'boqName': PropertySchema(
      id: 0,
      name: r'boqName',
      type: IsarType.string,
    ),
    r'boqNumber': PropertySchema(
      id: 1,
      name: r'boqNumber',
      type: IsarType.string,
    ),
    r'progressPercentage': PropertySchema(
      id: 2,
      name: r'progressPercentage',
      type: IsarType.double,
    ),
    r'remainingQuantity': PropertySchema(
      id: 3,
      name: r'remainingQuantity',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 4,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'siteId': PropertySchema(
      id: 5,
      name: r'siteId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 6,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalItems': PropertySchema(
      id: 7,
      name: r'totalItems',
      type: IsarType.long,
    ),
    r'totalNetWeight': PropertySchema(
      id: 8,
      name: r'totalNetWeight',
      type: IsarType.double,
    ),
    r'totalQuantity': PropertySchema(
      id: 9,
      name: r'totalQuantity',
      type: IsarType.double,
    ),
    r'uploadedAt': PropertySchema(
      id: 10,
      name: r'uploadedAt',
      type: IsarType.dateTime,
    ),
    r'usedQuantity': PropertySchema(
      id: 11,
      name: r'usedQuantity',
      type: IsarType.double,
    )
  },
  estimateSize: _bOQStructureIsarEstimateSize,
  serialize: _bOQStructureIsarSerialize,
  deserialize: _bOQStructureIsarDeserialize,
  deserializeProp: _bOQStructureIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
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
  links: {
    r'items': LinkSchema(
      id: -3503523009448288235,
      name: r'items',
      target: r'BOQItemIsar',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _bOQStructureIsarGetId,
  getLinks: _bOQStructureIsarGetLinks,
  attach: _bOQStructureIsarAttach,
  version: '3.3.0',
);

int _bOQStructureIsarEstimateSize(
  BOQStructureIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.boqName.length * 3;
  bytesCount += 3 + object.boqNumber.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.siteId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _bOQStructureIsarSerialize(
  BOQStructureIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.boqName);
  writer.writeString(offsets[1], object.boqNumber);
  writer.writeDouble(offsets[2], object.progressPercentage);
  writer.writeDouble(offsets[3], object.remainingQuantity);
  writer.writeString(offsets[4], object.serverId);
  writer.writeString(offsets[5], object.siteId);
  writer.writeString(offsets[6], object.status);
  writer.writeLong(offsets[7], object.totalItems);
  writer.writeDouble(offsets[8], object.totalNetWeight);
  writer.writeDouble(offsets[9], object.totalQuantity);
  writer.writeDateTime(offsets[10], object.uploadedAt);
  writer.writeDouble(offsets[11], object.usedQuantity);
}

BOQStructureIsar _bOQStructureIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BOQStructureIsar();
  object.boqName = reader.readString(offsets[0]);
  object.boqNumber = reader.readString(offsets[1]);
  object.isarId = id;
  object.progressPercentage = reader.readDouble(offsets[2]);
  object.remainingQuantity = reader.readDouble(offsets[3]);
  object.serverId = reader.readString(offsets[4]);
  object.siteId = reader.readString(offsets[5]);
  object.status = reader.readString(offsets[6]);
  object.totalItems = reader.readLong(offsets[7]);
  object.totalNetWeight = reader.readDouble(offsets[8]);
  object.totalQuantity = reader.readDouble(offsets[9]);
  object.uploadedAt = reader.readDateTimeOrNull(offsets[10]);
  object.usedQuantity = reader.readDouble(offsets[11]);
  return object;
}

P _bOQStructureIsarDeserializeProp<P>(
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
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bOQStructureIsarGetId(BOQStructureIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _bOQStructureIsarGetLinks(BOQStructureIsar object) {
  return [object.items];
}

void _bOQStructureIsarAttach(
    IsarCollection<dynamic> col, Id id, BOQStructureIsar object) {
  object.isarId = id;
  object.items.attach(col, col.isar.collection<BOQItemIsar>(), r'items', id);
}

extension BOQStructureIsarByIndex on IsarCollection<BOQStructureIsar> {
  Future<BOQStructureIsar?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  BOQStructureIsar? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<BOQStructureIsar?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<BOQStructureIsar?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(BOQStructureIsar object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(BOQStructureIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<BOQStructureIsar> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<BOQStructureIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension BOQStructureIsarQueryWhereSort
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QWhere> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BOQStructureIsarQueryWhere
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QWhereClause> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
      siteIdEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'siteId',
        value: [siteId],
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterWhereClause>
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

extension BOQStructureIsarQueryFilter
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QFilterCondition> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'boqName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'boqName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'boqName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqName',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'boqName',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'boqNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'boqNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'boqNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      boqNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'boqNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      progressPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      progressPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      progressPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      progressPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progressPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      remainingQuantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      remainingQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      remainingQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      remainingQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      siteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      siteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      siteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      siteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusEqualTo(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusGreaterThan(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusLessThan(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusBetween(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusStartsWith(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusEndsWith(
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

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalItemsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalItems',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalItemsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalItems',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalItemsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalItems',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalItemsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalItems',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalNetWeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalNetWeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalNetWeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalNetWeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalNetWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalQuantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      totalQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uploadedAt',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uploadedAt',
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      uploadedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      usedQuantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      usedQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      usedQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      usedQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usedQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BOQStructureIsarQueryObject
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QFilterCondition> {}

extension BOQStructureIsarQueryLinks
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QFilterCondition> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition> items(
      FilterQuery<BOQItemIsar> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'items');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterFilterCondition>
      itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'items', lower, includeLower, upper, includeUpper);
    });
  }
}

extension BOQStructureIsarQuerySortBy
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QSortBy> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByBoqName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqName', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByBoqNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqName', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByBoqNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqNumber', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByBoqNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqNumber', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByRemainingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByRemainingQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQuantity', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByUsedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      sortByUsedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQuantity', Sort.desc);
    });
  }
}

extension BOQStructureIsarQuerySortThenBy
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QSortThenBy> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByBoqName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqName', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByBoqNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqName', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByBoqNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqNumber', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByBoqNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqNumber', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByRemainingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByRemainingQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQuantity', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByUsedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQuantity', Sort.asc);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QAfterSortBy>
      thenByUsedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQuantity', Sort.desc);
    });
  }
}

extension BOQStructureIsarQueryWhereDistinct
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct> {
  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct> distinctByBoqName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boqName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByBoqNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boqNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressPercentage');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByRemainingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingQuantity');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct> distinctBySiteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalItems');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalNetWeight');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalQuantity');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadedAt');
    });
  }

  QueryBuilder<BOQStructureIsar, BOQStructureIsar, QDistinct>
      distinctByUsedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedQuantity');
    });
  }
}

extension BOQStructureIsarQueryProperty
    on QueryBuilder<BOQStructureIsar, BOQStructureIsar, QQueryProperty> {
  QueryBuilder<BOQStructureIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<BOQStructureIsar, String, QQueryOperations> boqNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boqName');
    });
  }

  QueryBuilder<BOQStructureIsar, String, QQueryOperations> boqNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boqNumber');
    });
  }

  QueryBuilder<BOQStructureIsar, double, QQueryOperations>
      progressPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressPercentage');
    });
  }

  QueryBuilder<BOQStructureIsar, double, QQueryOperations>
      remainingQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingQuantity');
    });
  }

  QueryBuilder<BOQStructureIsar, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<BOQStructureIsar, String, QQueryOperations> siteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteId');
    });
  }

  QueryBuilder<BOQStructureIsar, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<BOQStructureIsar, int, QQueryOperations> totalItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalItems');
    });
  }

  QueryBuilder<BOQStructureIsar, double, QQueryOperations>
      totalNetWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalNetWeight');
    });
  }

  QueryBuilder<BOQStructureIsar, double, QQueryOperations>
      totalQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalQuantity');
    });
  }

  QueryBuilder<BOQStructureIsar, DateTime?, QQueryOperations>
      uploadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadedAt');
    });
  }

  QueryBuilder<BOQStructureIsar, double, QQueryOperations>
      usedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedQuantity');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBOQItemIsarCollection on Isar {
  IsarCollection<BOQItemIsar> get bOQItemIsars => this.collection();
}

const BOQItemIsarSchema = CollectionSchema(
  name: r'BOQItemIsar',
  id: 4362184876936794868,
  properties: {
    r'assemblyMark': PropertySchema(
      id: 0,
      name: r'assemblyMark',
      type: IsarType.string,
    ),
    r'availableQty': PropertySchema(
      id: 1,
      name: r'availableQty',
      type: IsarType.double,
    ),
    r'boqServerId': PropertySchema(
      id: 2,
      name: r'boqServerId',
      type: IsarType.string,
    ),
    r'height': PropertySchema(
      id: 3,
      name: r'height',
      type: IsarType.double,
    ),
    r'length': PropertySchema(
      id: 4,
      name: r'length',
      type: IsarType.double,
    ),
    r'netWeightPerUnit': PropertySchema(
      id: 5,
      name: r'netWeightPerUnit',
      type: IsarType.double,
    ),
    r'progressPercentage': PropertySchema(
      id: 6,
      name: r'progressPercentage',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 7,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'remainingQty': PropertySchema(
      id: 8,
      name: r'remainingQty',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 9,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'totalNetWeight': PropertySchema(
      id: 10,
      name: r'totalNetWeight',
      type: IsarType.double,
    ),
    r'usedQty': PropertySchema(
      id: 11,
      name: r'usedQty',
      type: IsarType.double,
    ),
    r'width': PropertySchema(
      id: 12,
      name: r'width',
      type: IsarType.double,
    )
  },
  estimateSize: _bOQItemIsarEstimateSize,
  serialize: _bOQItemIsarSerialize,
  deserialize: _bOQItemIsarDeserialize,
  deserializeProp: _bOQItemIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'boqServerId': IndexSchema(
      id: -5123878478252221480,
      name: r'boqServerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'boqServerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _bOQItemIsarGetId,
  getLinks: _bOQItemIsarGetLinks,
  attach: _bOQItemIsarAttach,
  version: '3.3.0',
);

int _bOQItemIsarEstimateSize(
  BOQItemIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assemblyMark.length * 3;
  bytesCount += 3 + object.boqServerId.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  return bytesCount;
}

void _bOQItemIsarSerialize(
  BOQItemIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assemblyMark);
  writer.writeDouble(offsets[1], object.availableQty);
  writer.writeString(offsets[2], object.boqServerId);
  writer.writeDouble(offsets[3], object.height);
  writer.writeDouble(offsets[4], object.length);
  writer.writeDouble(offsets[5], object.netWeightPerUnit);
  writer.writeDouble(offsets[6], object.progressPercentage);
  writer.writeDouble(offsets[7], object.quantity);
  writer.writeDouble(offsets[8], object.remainingQty);
  writer.writeString(offsets[9], object.serverId);
  writer.writeDouble(offsets[10], object.totalNetWeight);
  writer.writeDouble(offsets[11], object.usedQty);
  writer.writeDouble(offsets[12], object.width);
}

BOQItemIsar _bOQItemIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BOQItemIsar();
  object.assemblyMark = reader.readString(offsets[0]);
  object.availableQty = reader.readDouble(offsets[1]);
  object.boqServerId = reader.readString(offsets[2]);
  object.height = reader.readDoubleOrNull(offsets[3]);
  object.isarId = id;
  object.length = reader.readDoubleOrNull(offsets[4]);
  object.netWeightPerUnit = reader.readDoubleOrNull(offsets[5]);
  object.progressPercentage = reader.readDouble(offsets[6]);
  object.quantity = reader.readDouble(offsets[7]);
  object.remainingQty = reader.readDouble(offsets[8]);
  object.serverId = reader.readString(offsets[9]);
  object.totalNetWeight = reader.readDoubleOrNull(offsets[10]);
  object.usedQty = reader.readDouble(offsets[11]);
  object.width = reader.readDoubleOrNull(offsets[12]);
  return object;
}

P _bOQItemIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bOQItemIsarGetId(BOQItemIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _bOQItemIsarGetLinks(BOQItemIsar object) {
  return [];
}

void _bOQItemIsarAttach(
    IsarCollection<dynamic> col, Id id, BOQItemIsar object) {
  object.isarId = id;
}

extension BOQItemIsarQueryWhereSort
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QWhere> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BOQItemIsarQueryWhere
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QWhereClause> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
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

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> serverIdEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> serverIdNotEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause> boqServerIdEqualTo(
      String boqServerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'boqServerId',
        value: [boqServerId],
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterWhereClause>
      boqServerIdNotEqualTo(String boqServerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqServerId',
              lower: [],
              upper: [boqServerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqServerId',
              lower: [boqServerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqServerId',
              lower: [boqServerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqServerId',
              lower: [],
              upper: [boqServerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension BOQItemIsarQueryFilter
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QFilterCondition> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assemblyMark',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assemblyMark',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assemblyMark',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      assemblyMarkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assemblyMark',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      availableQtyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availableQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      availableQtyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'availableQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      availableQtyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'availableQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      availableQtyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'availableQty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'boqServerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'boqServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'boqServerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqServerId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      boqServerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'boqServerId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> heightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      heightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> heightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> heightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
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

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> isarIdLessThan(
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

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> lengthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'length',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      lengthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'length',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> lengthEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      lengthGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> lengthLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> lengthBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'length',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'netWeightPerUnit',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'netWeightPerUnit',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'netWeightPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'netWeightPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'netWeightPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      netWeightPerUnitBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'netWeightPerUnit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      progressPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      progressPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      progressPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progressPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      progressPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progressPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> quantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      remainingQtyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      remainingQtyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      remainingQtyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      remainingQtyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingQty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> serverIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalNetWeight',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalNetWeight',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalNetWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      totalNetWeightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalNetWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> usedQtyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usedQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      usedQtyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usedQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> usedQtyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usedQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> usedQtyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usedQty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> widthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      widthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> widthEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition>
      widthGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> widthLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterFilterCondition> widthBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BOQItemIsarQueryObject
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QFilterCondition> {}

extension BOQItemIsarQueryLinks
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QFilterCondition> {}

extension BOQItemIsarQuerySortBy
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QSortBy> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByAssemblyMark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByAssemblyMarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByAvailableQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByBoqServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqServerId', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByBoqServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqServerId', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByNetWeightPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByRemainingQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      sortByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByUsedQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension BOQItemIsarQuerySortThenBy
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QSortThenBy> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByAssemblyMark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByAssemblyMarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByAvailableQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByBoqServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqServerId', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByBoqServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqServerId', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByNetWeightPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByRemainingQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy>
      thenByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByUsedQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.desc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QAfterSortBy> thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension BOQItemIsarQueryWhereDistinct
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> {
  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByAssemblyMark(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assemblyMark', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availableQty');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByBoqServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boqServerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'length');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct>
      distinctByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netWeightPerUnit');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct>
      distinctByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressPercentage');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingQty');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalNetWeight');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedQty');
    });
  }

  QueryBuilder<BOQItemIsar, BOQItemIsar, QDistinct> distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension BOQItemIsarQueryProperty
    on QueryBuilder<BOQItemIsar, BOQItemIsar, QQueryProperty> {
  QueryBuilder<BOQItemIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<BOQItemIsar, String, QQueryOperations> assemblyMarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assemblyMark');
    });
  }

  QueryBuilder<BOQItemIsar, double, QQueryOperations> availableQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availableQty');
    });
  }

  QueryBuilder<BOQItemIsar, String, QQueryOperations> boqServerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boqServerId');
    });
  }

  QueryBuilder<BOQItemIsar, double?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<BOQItemIsar, double?, QQueryOperations> lengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'length');
    });
  }

  QueryBuilder<BOQItemIsar, double?, QQueryOperations>
      netWeightPerUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netWeightPerUnit');
    });
  }

  QueryBuilder<BOQItemIsar, double, QQueryOperations>
      progressPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressPercentage');
    });
  }

  QueryBuilder<BOQItemIsar, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<BOQItemIsar, double, QQueryOperations> remainingQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingQty');
    });
  }

  QueryBuilder<BOQItemIsar, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<BOQItemIsar, double?, QQueryOperations>
      totalNetWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalNetWeight');
    });
  }

  QueryBuilder<BOQItemIsar, double, QQueryOperations> usedQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedQty');
    });
  }

  QueryBuilder<BOQItemIsar, double?, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }
}
