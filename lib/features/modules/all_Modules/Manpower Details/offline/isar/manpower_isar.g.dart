// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manpower_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetManpowerIsarCollection on Isar {
  IsarCollection<ManpowerIsar> get manpowerIsars => this.collection();
}

const ManpowerIsarSchema = CollectionSchema(
  name: r'ManpowerIsar',
  id: 6678546521407801451,
  properties: {
    r'aadharNumber': PropertySchema(
      id: 0,
      name: r'aadharNumber',
      type: IsarType.string,
    ),
    r'bankAccountNumber': PropertySchema(
      id: 1,
      name: r'bankAccountNumber',
      type: IsarType.string,
    ),
    r'basicSalary': PropertySchema(
      id: 2,
      name: r'basicSalary',
      type: IsarType.double,
    ),
    r'company': PropertySchema(
      id: 3,
      name: r'company',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.string,
    ),
    r'dateOfBirth': PropertySchema(
      id: 5,
      name: r'dateOfBirth',
      type: IsarType.string,
    ),
    r'dateOfJoining': PropertySchema(
      id: 6,
      name: r'dateOfJoining',
      type: IsarType.string,
    ),
    r'dearnessAllowance': PropertySchema(
      id: 7,
      name: r'dearnessAllowance',
      type: IsarType.double,
    ),
    r'designation': PropertySchema(
      id: 8,
      name: r'designation',
      type: IsarType.string,
    ),
    r'employeeCode': PropertySchema(
      id: 9,
      name: r'employeeCode',
      type: IsarType.string,
    ),
    r'epfNumber': PropertySchema(
      id: 10,
      name: r'epfNumber',
      type: IsarType.string,
    ),
    r'esicNumber': PropertySchema(
      id: 11,
      name: r'esicNumber',
      type: IsarType.string,
    ),
    r'fullName': PropertySchema(
      id: 12,
      name: r'fullName',
      type: IsarType.string,
    ),
    r'hra': PropertySchema(
      id: 13,
      name: r'hra',
      type: IsarType.double,
    ),
    r'ifscCode': PropertySchema(
      id: 14,
      name: r'ifscCode',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 15,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isLeft': PropertySchema(
      id: 16,
      name: r'isLeft',
      type: IsarType.bool,
    ),
    r'isLoginEnabled': PropertySchema(
      id: 17,
      name: r'isLoginEnabled',
      type: IsarType.bool,
    ),
    r'loginEmail': PropertySchema(
      id: 18,
      name: r'loginEmail',
      type: IsarType.string,
    ),
    r'loginPassword': PropertySchema(
      id: 19,
      name: r'loginPassword',
      type: IsarType.string,
    ),
    r'manpowerId': PropertySchema(
      id: 20,
      name: r'manpowerId',
      type: IsarType.string,
    ),
    r'medicalAllowance': PropertySchema(
      id: 21,
      name: r'medicalAllowance',
      type: IsarType.double,
    ),
    r'panNumber': PropertySchema(
      id: 22,
      name: r'panNumber',
      type: IsarType.string,
    ),
    r'payBasics': PropertySchema(
      id: 23,
      name: r'payBasics',
      type: IsarType.string,
    ),
    r'pfApplicable': PropertySchema(
      id: 24,
      name: r'pfApplicable',
      type: IsarType.bool,
    ),
    r'phoneNumber': PropertySchema(
      id: 25,
      name: r'phoneNumber',
      type: IsarType.string,
    ),
    r'reason': PropertySchema(
      id: 26,
      name: r'reason',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 27,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'salary': PropertySchema(
      id: 28,
      name: r'salary',
      type: IsarType.double,
    ),
    r'specialAllowance': PropertySchema(
      id: 29,
      name: r'specialAllowance',
      type: IsarType.double,
    ),
    r'travelAllowance': PropertySchema(
      id: 30,
      name: r'travelAllowance',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 31,
      name: r'type',
      type: IsarType.string,
    ),
    r'uanNumber': PropertySchema(
      id: 32,
      name: r'uanNumber',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 33,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _manpowerIsarEstimateSize,
  serialize: _manpowerIsarSerialize,
  deserialize: _manpowerIsarDeserialize,
  deserializeProp: _manpowerIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'manpowerId': IndexSchema(
      id: -4902541461226653662,
      name: r'manpowerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'manpowerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _manpowerIsarGetId,
  getLinks: _manpowerIsarGetLinks,
  attach: _manpowerIsarAttach,
  version: '3.1.0+1',
);

int _manpowerIsarEstimateSize(
  ManpowerIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aadharNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.bankAccountNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.company;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdAt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateOfBirth;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateOfJoining;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.designation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.employeeCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.epfNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.esicNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fullName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ifscCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.loginEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.loginPassword;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.manpowerId.length * 3;
  {
    final value = object.panNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.payBasics;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.phoneNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  {
    final value = object.uanNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _manpowerIsarSerialize(
  ManpowerIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aadharNumber);
  writer.writeString(offsets[1], object.bankAccountNumber);
  writer.writeDouble(offsets[2], object.basicSalary);
  writer.writeString(offsets[3], object.company);
  writer.writeString(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.dateOfBirth);
  writer.writeString(offsets[6], object.dateOfJoining);
  writer.writeDouble(offsets[7], object.dearnessAllowance);
  writer.writeString(offsets[8], object.designation);
  writer.writeString(offsets[9], object.employeeCode);
  writer.writeString(offsets[10], object.epfNumber);
  writer.writeString(offsets[11], object.esicNumber);
  writer.writeString(offsets[12], object.fullName);
  writer.writeDouble(offsets[13], object.hra);
  writer.writeString(offsets[14], object.ifscCode);
  writer.writeBool(offsets[15], object.isDeleted);
  writer.writeBool(offsets[16], object.isLeft);
  writer.writeBool(offsets[17], object.isLoginEnabled);
  writer.writeString(offsets[18], object.loginEmail);
  writer.writeString(offsets[19], object.loginPassword);
  writer.writeString(offsets[20], object.manpowerId);
  writer.writeDouble(offsets[21], object.medicalAllowance);
  writer.writeString(offsets[22], object.panNumber);
  writer.writeString(offsets[23], object.payBasics);
  writer.writeBool(offsets[24], object.pfApplicable);
  writer.writeString(offsets[25], object.phoneNumber);
  writer.writeString(offsets[26], object.reason);
  writer.writeString(offsets[27], object.remarks);
  writer.writeDouble(offsets[28], object.salary);
  writer.writeDouble(offsets[29], object.specialAllowance);
  writer.writeDouble(offsets[30], object.travelAllowance);
  writer.writeString(offsets[31], object.type);
  writer.writeString(offsets[32], object.uanNumber);
  writer.writeDateTime(offsets[33], object.updatedAt);
}

ManpowerIsar _manpowerIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ManpowerIsar();
  object.aadharNumber = reader.readStringOrNull(offsets[0]);
  object.bankAccountNumber = reader.readStringOrNull(offsets[1]);
  object.basicSalary = reader.readDoubleOrNull(offsets[2]);
  object.company = reader.readStringOrNull(offsets[3]);
  object.createdAt = reader.readStringOrNull(offsets[4]);
  object.dateOfBirth = reader.readStringOrNull(offsets[5]);
  object.dateOfJoining = reader.readStringOrNull(offsets[6]);
  object.dearnessAllowance = reader.readDoubleOrNull(offsets[7]);
  object.designation = reader.readStringOrNull(offsets[8]);
  object.employeeCode = reader.readStringOrNull(offsets[9]);
  object.epfNumber = reader.readStringOrNull(offsets[10]);
  object.esicNumber = reader.readStringOrNull(offsets[11]);
  object.fullName = reader.readStringOrNull(offsets[12]);
  object.hra = reader.readDoubleOrNull(offsets[13]);
  object.ifscCode = reader.readStringOrNull(offsets[14]);
  object.isDeleted = reader.readBool(offsets[15]);
  object.isLeft = reader.readBool(offsets[16]);
  object.isLoginEnabled = reader.readBoolOrNull(offsets[17]);
  object.isarId = id;
  object.loginEmail = reader.readStringOrNull(offsets[18]);
  object.loginPassword = reader.readStringOrNull(offsets[19]);
  object.manpowerId = reader.readString(offsets[20]);
  object.medicalAllowance = reader.readDoubleOrNull(offsets[21]);
  object.panNumber = reader.readStringOrNull(offsets[22]);
  object.payBasics = reader.readStringOrNull(offsets[23]);
  object.pfApplicable = reader.readBoolOrNull(offsets[24]);
  object.phoneNumber = reader.readStringOrNull(offsets[25]);
  object.reason = reader.readStringOrNull(offsets[26]);
  object.remarks = reader.readStringOrNull(offsets[27]);
  object.salary = reader.readDoubleOrNull(offsets[28]);
  object.specialAllowance = reader.readDoubleOrNull(offsets[29]);
  object.travelAllowance = reader.readDoubleOrNull(offsets[30]);
  object.type = reader.readString(offsets[31]);
  object.uanNumber = reader.readStringOrNull(offsets[32]);
  object.updatedAt = reader.readDateTime(offsets[33]);
  return object;
}

P _manpowerIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readBoolOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readBoolOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readDoubleOrNull(offset)) as P;
    case 29:
      return (reader.readDoubleOrNull(offset)) as P;
    case 30:
      return (reader.readDoubleOrNull(offset)) as P;
    case 31:
      return (reader.readString(offset)) as P;
    case 32:
      return (reader.readStringOrNull(offset)) as P;
    case 33:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _manpowerIsarGetId(ManpowerIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _manpowerIsarGetLinks(ManpowerIsar object) {
  return [];
}

void _manpowerIsarAttach(
    IsarCollection<dynamic> col, Id id, ManpowerIsar object) {
  object.isarId = id;
}

extension ManpowerIsarQueryWhereSort
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QWhere> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ManpowerIsarQueryWhere
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QWhereClause> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> isarIdNotEqualTo(
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> manpowerIdEqualTo(
      String manpowerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'manpowerId',
        value: [manpowerId],
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause>
      manpowerIdNotEqualTo(String manpowerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manpowerId',
              lower: [],
              upper: [manpowerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manpowerId',
              lower: [manpowerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manpowerId',
              lower: [manpowerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manpowerId',
              lower: [],
              upper: [manpowerId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> typeEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterWhereClause> typeNotEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ManpowerIsarQueryFilter
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QFilterCondition> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aadharNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aadharNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aadharNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aadharNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aadharNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aadharNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      aadharNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aadharNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bankAccountNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bankAccountNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bankAccountNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bankAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bankAccountNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankAccountNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      bankAccountNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bankAccountNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'basicSalary',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'basicSalary',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basicSalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basicSalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basicSalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      basicSalaryBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basicSalary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'company',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'company',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'company',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'company',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'company',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'company',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      companyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'company',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdAt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      createdAtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdAt',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateOfBirth',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateOfBirth',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateOfBirth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateOfBirth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateOfBirth',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateOfBirth',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfBirthIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateOfBirth',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateOfJoining',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateOfJoining',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateOfJoining',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateOfJoining',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateOfJoining',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateOfJoining',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dateOfJoiningIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateOfJoining',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dearnessAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dearnessAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dearnessAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dearnessAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dearnessAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      dearnessAllowanceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dearnessAllowance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'designation',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'designation',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'designation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'designation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'designation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'designation',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      designationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'designation',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'employeeCode',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'employeeCode',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'employeeCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'employeeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'employeeCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      employeeCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'employeeCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'epfNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'epfNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'epfNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'epfNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'epfNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'epfNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      epfNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'epfNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'esicNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'esicNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'esicNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'esicNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'esicNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'esicNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      esicNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'esicNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fullName',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fullName',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fullName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fullName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullName',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      fullNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fullName',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> hraIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hra',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      hraIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hra',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> hraEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hra',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      hraGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hra',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> hraLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hra',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> hraBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hra',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ifscCode',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ifscCode',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ifscCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ifscCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ifscCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      ifscCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ifscCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> isLeftEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLeft',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      isLoginEnabledIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isLoginEnabled',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      isLoginEnabledIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isLoginEnabled',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      isLoginEnabledEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLoginEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'loginEmail',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'loginEmail',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loginEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'loginEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'loginEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loginEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'loginEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'loginPassword',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'loginPassword',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loginPassword',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'loginPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'loginPassword',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loginPassword',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      loginPasswordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'loginPassword',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'manpowerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'manpowerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'manpowerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manpowerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      manpowerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'manpowerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'medicalAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'medicalAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'medicalAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'medicalAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'medicalAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      medicalAllowanceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'medicalAllowance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'panNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'panNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'panNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'panNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'panNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'panNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      panNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'panNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'payBasics',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'payBasics',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payBasics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payBasics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payBasics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payBasics',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      payBasicsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payBasics',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      pfApplicableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pfApplicable',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      pfApplicableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pfApplicable',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      pfApplicableEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pfApplicable',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phoneNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phoneNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phoneNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phoneNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      phoneNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phoneNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reason',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reason',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> reasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> reasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> reasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksEqualTo(
    String? value, {
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksLessThan(
    String? value, {
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
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

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      salaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'salary',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      salaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'salary',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> salaryEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'salary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      salaryGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'salary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      salaryLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'salary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> salaryBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'salary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'specialAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'specialAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'specialAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'specialAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'specialAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      specialAllowanceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'specialAllowance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'travelAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'travelAllowance',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'travelAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'travelAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'travelAllowance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      travelAllowanceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'travelAllowance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uanNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uanNumber',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uanNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uanNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uanNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uanNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      uanNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uanNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ManpowerIsarQueryObject
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QFilterCondition> {}

extension ManpowerIsarQueryLinks
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QFilterCondition> {}

extension ManpowerIsarQuerySortBy
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QSortBy> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByAadharNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aadharNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByAadharNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aadharNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByBankAccountNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByBankAccountNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByBasicSalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basicSalary', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByBasicSalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basicSalary', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByCompany() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'company', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByCompanyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'company', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByDateOfBirth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfBirth', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByDateOfBirthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfBirth', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByDateOfJoining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfJoining', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByDateOfJoiningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfJoining', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByDearnessAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dearnessAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByDearnessAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dearnessAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByDesignation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designation', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByDesignationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designation', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByEmployeeCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeCode', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByEmployeeCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeCode', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByEpfNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epfNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByEpfNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epfNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByEsicNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esicNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByEsicNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esicNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByHra() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hra', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByHraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hra', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIfscCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIfscCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIsLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLeft', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByIsLeftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLeft', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByIsLoginEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoginEnabled', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByIsLoginEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoginEnabled', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByLoginEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginEmail', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByLoginEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginEmail', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByLoginPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginPassword', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByLoginPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginPassword', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByManpowerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manpowerId', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByManpowerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manpowerId', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByMedicalAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicalAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByMedicalAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicalAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPanNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'panNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPanNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'panNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPayBasics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payBasics', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPayBasicsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payBasics', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPfApplicable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pfApplicable', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByPfApplicableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pfApplicable', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByPhoneNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByPhoneNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortBySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salary', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortBySalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salary', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortBySpecialAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specialAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortBySpecialAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specialAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByTravelAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'travelAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      sortByTravelAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'travelAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByUanNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uanNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByUanNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uanNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ManpowerIsarQuerySortThenBy
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QSortThenBy> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByAadharNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aadharNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByAadharNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aadharNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByBankAccountNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByBankAccountNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByBasicSalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basicSalary', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByBasicSalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basicSalary', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByCompany() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'company', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByCompanyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'company', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByDateOfBirth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfBirth', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByDateOfBirthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfBirth', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByDateOfJoining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfJoining', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByDateOfJoiningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateOfJoining', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByDearnessAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dearnessAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByDearnessAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dearnessAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByDesignation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designation', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByDesignationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'designation', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByEmployeeCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeCode', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByEmployeeCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeCode', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByEpfNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epfNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByEpfNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epfNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByEsicNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esicNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByEsicNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esicNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByHra() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hra', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByHraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hra', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIfscCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIfscCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLeft', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsLeftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLeft', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByIsLoginEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoginEnabled', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByIsLoginEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoginEnabled', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByLoginEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginEmail', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByLoginEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginEmail', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByLoginPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginPassword', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByLoginPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loginPassword', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByManpowerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manpowerId', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByManpowerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manpowerId', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByMedicalAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicalAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByMedicalAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicalAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPanNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'panNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPanNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'panNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPayBasics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payBasics', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPayBasicsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payBasics', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPfApplicable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pfApplicable', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByPfApplicableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pfApplicable', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByPhoneNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByPhoneNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenBySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salary', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenBySalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salary', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenBySpecialAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specialAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenBySpecialAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specialAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByTravelAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'travelAllowance', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy>
      thenByTravelAllowanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'travelAllowance', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByUanNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uanNumber', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByUanNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uanNumber', Sort.desc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ManpowerIsarQueryWhereDistinct
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> {
  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByAadharNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aadharNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctByBankAccountNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bankAccountNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByBasicSalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basicSalary');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByCompany(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'company', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByCreatedAt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByDateOfBirth(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateOfBirth', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByDateOfJoining(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateOfJoining',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctByDearnessAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dearnessAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByDesignation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'designation', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByEmployeeCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'employeeCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByEpfNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'epfNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByEsicNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'esicNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByFullName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fullName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByHra() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hra');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByIfscCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ifscCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByIsLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLeft');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctByIsLoginEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLoginEnabled');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByLoginEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loginEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByLoginPassword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loginPassword',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByManpowerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manpowerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctByMedicalAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'medicalAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByPanNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'panNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByPayBasics(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payBasics', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByPfApplicable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pfApplicable');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByPhoneNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phoneNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctBySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'salary');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctBySpecialAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'specialAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct>
      distinctByTravelAllowance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'travelAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByUanNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uanNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManpowerIsar, ManpowerIsar, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ManpowerIsarQueryProperty
    on QueryBuilder<ManpowerIsar, ManpowerIsar, QQueryProperty> {
  QueryBuilder<ManpowerIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> aadharNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aadharNumber');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations>
      bankAccountNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bankAccountNumber');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations> basicSalaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basicSalary');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> companyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'company');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> dateOfBirthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateOfBirth');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations>
      dateOfJoiningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateOfJoining');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations>
      dearnessAllowanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dearnessAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> designationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'designation');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> employeeCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'employeeCode');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> epfNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'epfNumber');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> esicNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'esicNumber');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fullName');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations> hraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hra');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> ifscCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ifscCode');
    });
  }

  QueryBuilder<ManpowerIsar, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<ManpowerIsar, bool, QQueryOperations> isLeftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLeft');
    });
  }

  QueryBuilder<ManpowerIsar, bool?, QQueryOperations> isLoginEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLoginEnabled');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> loginEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loginEmail');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations>
      loginPasswordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loginPassword');
    });
  }

  QueryBuilder<ManpowerIsar, String, QQueryOperations> manpowerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manpowerId');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations>
      medicalAllowanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'medicalAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> panNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'panNumber');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> payBasicsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payBasics');
    });
  }

  QueryBuilder<ManpowerIsar, bool?, QQueryOperations> pfApplicableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pfApplicable');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> phoneNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phoneNumber');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> reasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reason');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations> salaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'salary');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations>
      specialAllowanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'specialAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, double?, QQueryOperations>
      travelAllowanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'travelAllowance');
    });
  }

  QueryBuilder<ManpowerIsar, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<ManpowerIsar, String?, QQueryOperations> uanNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uanNumber');
    });
  }

  QueryBuilder<ManpowerIsar, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
