// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_image.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedImageCollection on Isar {
  IsarCollection<CachedImage> get cachedImages => this.collection();
}

const CachedImageSchema = CollectionSchema(
  name: r'CachedImage',
  id: 616006537740141576,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'localPath': PropertySchema(
      id: 1,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'serverUrl': PropertySchema(
      id: 2,
      name: r'serverUrl',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedImageEstimateSize,
  serialize: _cachedImageSerialize,
  deserialize: _cachedImageDeserialize,
  deserializeProp: _cachedImageDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverUrl': IndexSchema(
      id: -750331035601889240,
      name: r'serverUrl',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverUrl',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedImageGetId,
  getLinks: _cachedImageGetLinks,
  attach: _cachedImageAttach,
  version: '3.3.0',
);

int _cachedImageEstimateSize(
  CachedImage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.localPath.length * 3;
  bytesCount += 3 + object.serverUrl.length * 3;
  return bytesCount;
}

void _cachedImageSerialize(
  CachedImage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.localPath);
  writer.writeString(offsets[2], object.serverUrl);
}

CachedImage _cachedImageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedImage();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.localPath = reader.readString(offsets[1]);
  object.serverUrl = reader.readString(offsets[2]);
  return object;
}

P _cachedImageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedImageGetId(CachedImage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedImageGetLinks(CachedImage object) {
  return [];
}

void _cachedImageAttach(
    IsarCollection<dynamic> col, Id id, CachedImage object) {
  object.id = id;
}

extension CachedImageByIndex on IsarCollection<CachedImage> {
  Future<CachedImage?> getByServerUrl(String serverUrl) {
    return getByIndex(r'serverUrl', [serverUrl]);
  }

  CachedImage? getByServerUrlSync(String serverUrl) {
    return getByIndexSync(r'serverUrl', [serverUrl]);
  }

  Future<bool> deleteByServerUrl(String serverUrl) {
    return deleteByIndex(r'serverUrl', [serverUrl]);
  }

  bool deleteByServerUrlSync(String serverUrl) {
    return deleteByIndexSync(r'serverUrl', [serverUrl]);
  }

  Future<List<CachedImage?>> getAllByServerUrl(List<String> serverUrlValues) {
    final values = serverUrlValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverUrl', values);
  }

  List<CachedImage?> getAllByServerUrlSync(List<String> serverUrlValues) {
    final values = serverUrlValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverUrl', values);
  }

  Future<int> deleteAllByServerUrl(List<String> serverUrlValues) {
    final values = serverUrlValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverUrl', values);
  }

  int deleteAllByServerUrlSync(List<String> serverUrlValues) {
    final values = serverUrlValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverUrl', values);
  }

  Future<Id> putByServerUrl(CachedImage object) {
    return putByIndex(r'serverUrl', object);
  }

  Id putByServerUrlSync(CachedImage object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverUrl', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerUrl(List<CachedImage> objects) {
    return putAllByIndex(r'serverUrl', objects);
  }

  List<Id> putAllByServerUrlSync(List<CachedImage> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverUrl', objects, saveLinks: saveLinks);
  }
}

extension CachedImageQueryWhereSort
    on QueryBuilder<CachedImage, CachedImage, QWhere> {
  QueryBuilder<CachedImage, CachedImage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedImageQueryWhere
    on QueryBuilder<CachedImage, CachedImage, QWhereClause> {
  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> serverUrlEqualTo(
      String serverUrl) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverUrl',
        value: [serverUrl],
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterWhereClause> serverUrlNotEqualTo(
      String serverUrl) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverUrl',
              lower: [],
              upper: [serverUrl],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverUrl',
              lower: [serverUrl],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverUrl',
              lower: [serverUrl],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverUrl',
              lower: [],
              upper: [serverUrl],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedImageQueryFilter
    on QueryBuilder<CachedImage, CachedImage, QFilterCondition> {
  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> cachedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterFilterCondition>
      serverUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverUrl',
        value: '',
      ));
    });
  }
}

extension CachedImageQueryObject
    on QueryBuilder<CachedImage, CachedImage, QFilterCondition> {}

extension CachedImageQueryLinks
    on QueryBuilder<CachedImage, CachedImage, QFilterCondition> {}

extension CachedImageQuerySortBy
    on QueryBuilder<CachedImage, CachedImage, QSortBy> {
  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByServerUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> sortByServerUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverUrl', Sort.desc);
    });
  }
}

extension CachedImageQuerySortThenBy
    on QueryBuilder<CachedImage, CachedImage, QSortThenBy> {
  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByServerUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QAfterSortBy> thenByServerUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverUrl', Sort.desc);
    });
  }
}

extension CachedImageQueryWhereDistinct
    on QueryBuilder<CachedImage, CachedImage, QDistinct> {
  QueryBuilder<CachedImage, CachedImage, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedImage, CachedImage, QDistinct> distinctByLocalPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedImage, CachedImage, QDistinct> distinctByServerUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverUrl', caseSensitive: caseSensitive);
    });
  }
}

extension CachedImageQueryProperty
    on QueryBuilder<CachedImage, CachedImage, QQueryProperty> {
  QueryBuilder<CachedImage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedImage, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedImage, String, QQueryOperations> localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<CachedImage, String, QQueryOperations> serverUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverUrl');
    });
  }
}
