// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipmentModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentItemAdapter extends TypeAdapter<EquipmentItem> {
  @override
  final int typeId = 1;

  @override
  EquipmentItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquipmentItem(
      id: fields[0] as String,
      materialName: fields[1] as String,
      image: fields[2] as String,
      qty: fields[3] as double,
      uom: fields[4] as String,
      length: fields[5] as double,
      rmt: fields[6] as double,
      diameter: fields[7] as double,
      weight: fields[8] as double,
      power: fields[9] as double,
      actualRate: fields[10] as double,
      rate: fields[11] as double,
      moc: fields[12] as String,
      size: fields[13] as String,
      location: fields[14] as String,
      plant: fields[15] as String,
      designation: (fields[16] as List).cast<String>(),
      calculationCategory: fields[17] as String,
      remarks: fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentItem obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.materialName)
      ..writeByte(2)
      ..write(obj.image)
      ..writeByte(3)
      ..write(obj.qty)
      ..writeByte(4)
      ..write(obj.uom)
      ..writeByte(5)
      ..write(obj.length)
      ..writeByte(6)
      ..write(obj.rmt)
      ..writeByte(7)
      ..write(obj.diameter)
      ..writeByte(8)
      ..write(obj.weight)
      ..writeByte(9)
      ..write(obj.power)
      ..writeByte(10)
      ..write(obj.actualRate)
      ..writeByte(11)
      ..write(obj.rate)
      ..writeByte(12)
      ..write(obj.moc)
      ..writeByte(13)
      ..write(obj.size)
      ..writeByte(14)
      ..write(obj.location)
      ..writeByte(15)
      ..write(obj.plant)
      ..writeByte(16)
      ..write(obj.designation)
      ..writeByte(17)
      ..write(obj.calculationCategory)
      ..writeByte(18)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
