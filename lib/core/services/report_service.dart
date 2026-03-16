import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    final reportId = _firestore.collection('reports').doc().id;
    
    final report = ReportModel(
      id: reportId,
      reporterId: reporterId,
      reportedId: reportedUserId,
      reportedType: 'user',
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('reports').doc(reportId).set(report.toJson());
  }

  Future<void> reportJob({
    required String reporterId,
    required String jobId,
    required String reason,
    required String description,
  }) async {
    final reportId = _firestore.collection('reports').doc().id;
    
    final report = ReportModel(
      id: reportId,
      reporterId: reporterId,
      reportedId: jobId,
      reportedType: 'job',
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('reports').doc(reportId).set(report.toJson());
  }
}
