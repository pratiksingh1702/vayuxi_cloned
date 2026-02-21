// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LanguageModuleAdapter extends TypeAdapter<LanguageModule> {
  @override
  final int typeId = 1;

  @override
  LanguageModule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LanguageModule(
      languageCode: fields[0] as String,
      moduleName: fields[1] as String,
      content: (fields[2] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, LanguageModule obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.languageCode)
      ..writeByte(1)
      ..write(obj.moduleName)
      ..writeByte(2)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
