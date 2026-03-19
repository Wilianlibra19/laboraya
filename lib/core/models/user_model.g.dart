// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      photo: fields[2] as String?,
      phone: fields[3] as String,
      email: fields[4] as String,
      district: fields[5] as String,
      rating: fields[6] as double,
      completedJobs: fields[7] as int,
      skills: (fields[8] as List).cast<String>(),
      availability: fields[9] as String,
      description: fields[10] as String,
      documents: (fields[11] as List).cast<String>(),
      createdAt: fields[12] as DateTime,
      isDniVerified: fields[13] as bool,
      isPhoneVerified: fields[14] as bool,
      isDocumentVerified: fields[15] as bool,
      totalEarnings: fields[16] as double,
      monthlyEarnings: fields[17] as double,
      totalReviews: fields[18] as int,
      credits: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photo)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.district)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.completedJobs)
      ..writeByte(8)
      ..write(obj.skills)
      ..writeByte(9)
      ..write(obj.availability)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.documents)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.isDniVerified)
      ..writeByte(14)
      ..write(obj.isPhoneVerified)
      ..writeByte(15)
      ..write(obj.isDocumentVerified)
      ..writeByte(16)
      ..write(obj.totalEarnings)
      ..writeByte(17)
      ..write(obj.monthlyEarnings)
      ..writeByte(18)
      ..write(obj.totalReviews)
      ..writeByte(19)
      ..write(obj.credits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
