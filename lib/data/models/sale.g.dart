// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 0;

  @override
  Sale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sale(
      id: fields[0] as String,
      amount: fields[1] as double,
      paymentType: fields[2] as String,
      customerId: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.paymentType)
      ..writeByte(3)
      ..write(obj.customerId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
