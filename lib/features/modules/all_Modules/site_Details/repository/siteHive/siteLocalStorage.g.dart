// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'siteLocalStorage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteModelHiveAdapter extends TypeAdapter<SiteModelHive> {
  @override
  final int typeId = 0;

  @override
  SiteModelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteModelHive(
      id: fields[0] as String,
      siteName: fields[1] as String,
      address: fields[2] as String,
      contactPerson: fields[3] as String,
      gstNo: fields[4] as String,
      phoneNumber: fields[5] as String,
      emailId: fields[6] as String,
      documentDate: fields[7] as String?,
      documentNumber: fields[8] as String,
      isDeleted: fields[9] as bool,
      company: fields[10] as String,
      type: fields[11] as String,
      createdAt: fields[12] as String,
      updatedAt: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SiteModelHive obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteName)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.contactPerson)
      ..writeByte(4)
      ..write(obj.gstNo)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.emailId)
      ..writeByte(7)
      ..write(obj.documentDate)
      ..writeByte(8)
      ..write(obj.documentNumber)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.company)
      ..writeByte(11)
      ..write(obj.type)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
