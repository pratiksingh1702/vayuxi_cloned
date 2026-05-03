// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assembly_card_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssemblyCardIsarCollection on Isar {
  IsarCollection<AssemblyCardIsar> get assemblyCardIsars => this.collection();
}

const AssemblyCardIsarSchema = CollectionSchema(
  name: r'AssemblyCardIsar',
  id: -3624276424657682441,
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
    r'boqItemId': PropertySchema(
      id: 2,
      name: r'boqItemId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'height': PropertySchema(
      id: 5,
      name: r'height',
      type: IsarType.double,
    ),
    r'isSynced': PropertySchema(
      id: 6,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'length': PropertySchema(
      id: 7,
      name: r'length',
      type: IsarType.double,
    ),
    r'netWeightPerUnit': PropertySchema(
      id: 8,
      name: r'netWeightPerUnit',
      type: IsarType.double,
    ),
    r'progressPercentage': PropertySchema(
      id: 9,
      name: r'progressPercentage',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 10,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'remainingQty': PropertySchema(
      id: 11,
      name: r'remainingQty',
      type: IsarType.double,
    ),
    r'siteId': PropertySchema(
      id: 12,
      name: r'siteId',
      type: IsarType.string,
    ),
    r'totalNetWeight': PropertySchema(
      id: 13,
      name: r'totalNetWeight',
      type: IsarType.double,
    ),
    r'usedQty': PropertySchema(
      id: 14,
      name: r'usedQty',
      type: IsarType.double,
    ),
    r'width': PropertySchema(
      id: 15,
      name: r'width',
      type: IsarType.double,
    )
  },
  estimateSize: _assemblyCardIsarEstimateSize,
  serialize: _assemblyCardIsarSerialize,
  deserialize: _assemblyCardIsarDeserialize,
  deserializeProp: _assemblyCardIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
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
    r'boqItemId': IndexSchema(
      id: -4867539802118118803,
      name: r'boqItemId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'boqItemId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _assemblyCardIsarGetId,
  getLinks: _assemblyCardIsarGetLinks,
  attach: _assemblyCardIsarAttach,
  version: '3.3.0',
);

int _assemblyCardIsarEstimateSize(
  AssemblyCardIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assemblyMark.length * 3;
  bytesCount += 3 + object.boqItemId.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.siteId.length * 3;
  return bytesCount;
}

void _assemblyCardIsarSerialize(
  AssemblyCardIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assemblyMark);
  writer.writeDouble(offsets[1], object.availableQty);
  writer.writeString(offsets[2], object.boqItemId);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.description);
  writer.writeDouble(offsets[5], object.height);
  writer.writeBool(offsets[6], object.isSynced);
  writer.writeDouble(offsets[7], object.length);
  writer.writeDouble(offsets[8], object.netWeightPerUnit);
  writer.writeDouble(offsets[9], object.progressPercentage);
  writer.writeDouble(offsets[10], object.quantity);
  writer.writeDouble(offsets[11], object.remainingQty);
  writer.writeString(offsets[12], object.siteId);
  writer.writeDouble(offsets[13], object.totalNetWeight);
  writer.writeDouble(offsets[14], object.usedQty);
  writer.writeDouble(offsets[15], object.width);
}

AssemblyCardIsar _assemblyCardIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssemblyCardIsar();
  object.assemblyMark = reader.readString(offsets[0]);
  object.availableQty = reader.readDouble(offsets[1]);
  object.boqItemId = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.description = reader.readString(offsets[4]);
  object.height = reader.readDoubleOrNull(offsets[5]);
  object.isSynced = reader.readBool(offsets[6]);
  object.isarId = id;
  object.length = reader.readDoubleOrNull(offsets[7]);
  object.netWeightPerUnit = reader.readDoubleOrNull(offsets[8]);
  object.progressPercentage = reader.readDouble(offsets[9]);
  object.quantity = reader.readDouble(offsets[10]);
  object.remainingQty = reader.readDouble(offsets[11]);
  object.siteId = reader.readString(offsets[12]);
  object.totalNetWeight = reader.readDoubleOrNull(offsets[13]);
  object.usedQty = reader.readDouble(offsets[14]);
  object.width = reader.readDoubleOrNull(offsets[15]);
  return object;
}

P _assemblyCardIsarDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assemblyCardIsarGetId(AssemblyCardIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _assemblyCardIsarGetLinks(AssemblyCardIsar object) {
  return [];
}

void _assemblyCardIsarAttach(
    IsarCollection<dynamic> col, Id id, AssemblyCardIsar object) {
  object.isarId = id;
}

extension AssemblyCardIsarQueryWhereSort
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QWhere> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssemblyCardIsarQueryWhere
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QWhereClause> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      siteIdEqualTo(String siteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'siteId',
        value: [siteId],
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      boqItemIdEqualTo(String boqItemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'boqItemId',
        value: [boqItemId],
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterWhereClause>
      boqItemIdNotEqualTo(String boqItemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqItemId',
              lower: [],
              upper: [boqItemId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqItemId',
              lower: [boqItemId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqItemId',
              lower: [boqItemId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'boqItemId',
              lower: [],
              upper: [boqItemId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AssemblyCardIsarQueryFilter
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QFilterCondition> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      assemblyMarkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assemblyMark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      assemblyMarkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assemblyMark',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      assemblyMarkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assemblyMark',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      assemblyMarkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assemblyMark',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'boqItemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'boqItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'boqItemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'boqItemId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      boqItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'boqItemId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      heightEqualTo(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      heightLessThan(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      heightBetween(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      lengthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'length',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      lengthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'length',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      lengthEqualTo(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      lengthLessThan(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      lengthBetween(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      netWeightPerUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'netWeightPerUnit',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      netWeightPerUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'netWeightPerUnit',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      quantityEqualTo(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      quantityBetween(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      siteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      siteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      siteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      siteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      totalNetWeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalNetWeight',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      totalNetWeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalNetWeight',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      usedQtyEqualTo(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      usedQtyLessThan(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      usedQtyBetween(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      widthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      widthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      widthEqualTo(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      widthLessThan(
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

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterFilterCondition>
      widthBetween(
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

extension AssemblyCardIsarQueryObject
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QFilterCondition> {}

extension AssemblyCardIsarQueryLinks
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QFilterCondition> {}

extension AssemblyCardIsarQuerySortBy
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QSortBy> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByAssemblyMark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByAssemblyMarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByAvailableQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByBoqItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqItemId', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByBoqItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqItemId', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByNetWeightPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByRemainingQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByUsedQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension AssemblyCardIsarQuerySortThenBy
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QSortThenBy> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByAssemblyMark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByAssemblyMarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assemblyMark', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByAvailableQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByBoqItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqItemId', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByBoqItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boqItemId', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByNetWeightPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netWeightPerUnit', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByProgressPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercentage', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByRemainingQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenBySiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenBySiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteId', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByTotalNetWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetWeight', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByUsedQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedQty', Sort.desc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QAfterSortBy>
      thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension AssemblyCardIsarQueryWhereDistinct
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct> {
  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByAssemblyMark({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assemblyMark', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByAvailableQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availableQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByBoqItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boqItemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'length');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByNetWeightPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netWeightPerUnit');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByProgressPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressPercentage');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByRemainingQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct> distinctBySiteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByTotalNetWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalNetWeight');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByUsedQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QDistinct>
      distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension AssemblyCardIsarQueryProperty
    on QueryBuilder<AssemblyCardIsar, AssemblyCardIsar, QQueryProperty> {
  QueryBuilder<AssemblyCardIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<AssemblyCardIsar, String, QQueryOperations>
      assemblyMarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assemblyMark');
    });
  }

  QueryBuilder<AssemblyCardIsar, double, QQueryOperations>
      availableQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availableQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, String, QQueryOperations> boqItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boqItemId');
    });
  }

  QueryBuilder<AssemblyCardIsar, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AssemblyCardIsar, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<AssemblyCardIsar, double?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<AssemblyCardIsar, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<AssemblyCardIsar, double?, QQueryOperations> lengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'length');
    });
  }

  QueryBuilder<AssemblyCardIsar, double?, QQueryOperations>
      netWeightPerUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netWeightPerUnit');
    });
  }

  QueryBuilder<AssemblyCardIsar, double, QQueryOperations>
      progressPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressPercentage');
    });
  }

  QueryBuilder<AssemblyCardIsar, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<AssemblyCardIsar, double, QQueryOperations>
      remainingQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, String, QQueryOperations> siteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteId');
    });
  }

  QueryBuilder<AssemblyCardIsar, double?, QQueryOperations>
      totalNetWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalNetWeight');
    });
  }

  QueryBuilder<AssemblyCardIsar, double, QQueryOperations> usedQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedQty');
    });
  }

  QueryBuilder<AssemblyCardIsar, double?, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }
}
