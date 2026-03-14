// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobModelAdapter extends TypeAdapter<JobModel> {
  @override
  final int typeId = 1;

  @override
  JobModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      payment: fields[4] as double,
      paymentType: fields[5] as String,
      workersNeeded: fields[6] as int,
      duration: fields[7] as String,
      latitude: fields[8] as double,
      longitude: fields[9] as double,
      address: fields[10] as String,
      createdBy: fields[11] as String,
      acceptedBy: fields[12] as String?,
      status: fields[13] as String,
      isUrgent: fields[14] as bool,
      images: (fields[15] as List).cast<String>(),
      createdAt: fields[16] as DateTime,
      scheduledDate: fields[17] as DateTime?,
      jobStatus: fields[18] as String,
      acceptedAt: fields[19] as DateTime?,
      startedAt: fields[20] as DateTime?,
      finishedAt: fields[21] as DateTime?,
      confirmedAt: fields[22] as DateTime?,
      completedAt: fields[23] as DateTime?,
      ratingWorker: fields[24] as double?,
      commentWorker: fields[25] as String?,
      ratingClient: fields[26] as double?,
      commentClient: fields[27] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JobModel obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.payment)
      ..writeByte(5)
      ..write(obj.paymentType)
      ..writeByte(6)
      ..write(obj.workersNeeded)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.address)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.acceptedBy)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.isUrgent)
      ..writeByte(15)
      ..write(obj.images)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.scheduledDate)
      ..writeByte(18)
      ..write(obj.jobStatus)
      ..writeByte(19)
      ..write(obj.acceptedAt)
      ..writeByte(20)
      ..write(obj.startedAt)
      ..writeByte(21)
      ..write(obj.finishedAt)
      ..writeByte(22)
      ..write(obj.confirmedAt)
      ..writeByte(23)
      ..write(obj.completedAt)
      ..writeByte(24)
      ..write(obj.ratingWorker)
      ..writeByte(25)
      ..write(obj.commentWorker)
      ..writeByte(26)
      ..write(obj.ratingClient)
      ..writeByte(27)
      ..write(obj.commentClient);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
