import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/road_report.dart';

abstract class ReportRepository {
  Stream<List<RoadReport>> watchReports();
  Future<void> addReport(RoadReport report);
  Future<void> updateStatus(String id, ReportStatus status);
  // Tambahan fungsi upvoteReport
  Future<void> upvoteReport(String id);
}

class DummyReportRepository implements ReportRepository {
  final List<RoadReport> _reports = List.of(DummyData.reports);
  final StreamController<List<RoadReport>> _controller =
  StreamController<List<RoadReport>>.broadcast();

  DummyReportRepository() {
    Future.microtask(() => _controller.add(List.unmodifiable(_reports)));
  }

  @override
  Stream<List<RoadReport>> watchReports() async* {
    yield List.unmodifiable(_reports);
    yield* _controller.stream;
  }

  @override
  Future<void> addReport(RoadReport report) async {
    _reports.insert(0, report);
    _controller.add(List.unmodifiable(_reports));
  }

  @override
  Future<void> updateStatus(String id, ReportStatus status) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final old = _reports[idx];
    _reports[idx] = RoadReport(
      id: old.id,
      title: old.title,
      address: old.address,
      latitude: old.latitude,
      longitude: old.longitude,
      severity: old.severity,
      status: status,
      reportedAgo: old.reportedAgo,
      votes: old.votes,
      imagePath: old.imagePath,
      userId: old.userId,
      userName: old.userName,
      createdAt: old.createdAt,
    );
    _controller.add(List.unmodifiable(_reports));
  }

  @override
  Future<void> upvoteReport(String id) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final old = _reports[idx];
    _reports[idx] = RoadReport(
      id: old.id,
      title: old.title,
      address: old.address,
      latitude: old.latitude,
      longitude: old.longitude,
      severity: old.severity,
      status: old.status,
      reportedAgo: old.reportedAgo,
      votes: old.votes + 1, // Tambah jumlah vote sebanyak 1
      imagePath: old.imagePath,
      userId: old.userId,
      userName: old.userName,
      createdAt: old.createdAt,
    );
    _controller.add(List.unmodifiable(_reports));
  }
}

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'reports';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  @override
  Stream<List<RoadReport>> watchReports() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((doc) => RoadReport.fromFirestore(doc)).toList(),
    );
  }

  @override
  Future<void> addReport(RoadReport report) async {
    await _ref.add(report.toFirestore());
  }

  @override
  Future<void> updateStatus(String id, ReportStatus status) async {
    await _ref.doc(id).update({
      'status': switch (status) {
        ReportStatus.pending => 'pending',
        ReportStatus.inProgress => 'in_progress',
        ReportStatus.fixed => 'fixed',
      },
    });
  }

  @override
  Future<void> upvoteReport(String id) async {
    // Menggunakan Increment agar pembaruan data upvote aman (Atomic operation)
    await _ref.doc(id).update({
      'votes': FieldValue.increment(1),
    });
  }
}