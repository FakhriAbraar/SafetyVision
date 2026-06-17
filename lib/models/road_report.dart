import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum ReportSeverity { low, medium, high, other }

enum ReportStatus { pending, inProgress, fixed }

ReportSeverity _severityFromString(String? value) {
  switch (value) {
    case 'high':
      return ReportSeverity.high;
    case 'low':
      return ReportSeverity.low;
    case 'other':
      return ReportSeverity.other;
    case 'medium':
    default:
      return ReportSeverity.medium;
  }
}

String _severityToString(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.high:
      return 'high';
    case ReportSeverity.medium:
      return 'medium';
    case ReportSeverity.low:
      return 'low';
    case ReportSeverity.other:
      return 'other';
  }
}

ReportStatus _statusFromString(String? value) {
  switch (value) {
    case 'in_progress':
      return ReportStatus.inProgress;
    case 'fixed':
      return ReportStatus.fixed;
    case 'pending':
    default:
      return ReportStatus.pending;
  }
}

String _statusToString(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending:
      return 'pending';
    case ReportStatus.inProgress:
      return 'in_progress';
    case ReportStatus.fixed:
      return 'fixed';
  }
}

class RoadReport {
  final String id;
  final String title;
  final String address;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final ReportSeverity severity;
  final ReportStatus status;
  final String reportedAgo;
  final int votes;
  final String? imagePath; // path foto di penyimpanan lokal HP (bukan URL)
  final String? userId; // uid pemilik laporan (relasi ke user yang login)
  final String? userName; // nama pelapor (displayName user)
  final String? resolutionDescription; // deskripsi perbaikan dari admin
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoadReport({
    required this.id,
    required this.title,
    required this.address,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    required this.reportedAgo,
    required this.votes,
    this.imagePath,
    this.userId,
    this.userName,
    this.resolutionDescription,
    this.createdAt,
    this.updatedAt,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory RoadReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final created = (data['createdAt'] as Timestamp?)?.toDate();
    final updated = (data['updatedAt'] as Timestamp?)?.toDate();
    return RoadReport(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa judul',
      address: data['address'] as String? ?? '-',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Lainnya',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      severity: _severityFromString(data['severity'] as String?),
      status: _statusFromString(data['status'] as String?),
      reportedAgo: _formatAgo(created),
      votes: (data['votes'] as num?)?.toInt() ?? 0,
      imagePath: data['imagePath'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      resolutionDescription: data['resolutionDescription'] as String?,
      createdAt: created,
      updatedAt: updated ?? created, // fallback to createdAt if null
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'address': address,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'severity': _severityToString(severity),
      'status': _statusToString(status),
      'votes': votes,
      'imagePath': imagePath,
      'userId': userId,
      'userName': userName,
      'resolutionDescription': resolutionDescription,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }
}

String _formatAgo(DateTime? when) {
  if (when == null) return '-';
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
  if (diff.inHours < 24) return '${diff.inHours}j lalu';
  return '${diff.inDays}h lalu';
}

class DummyData {
  static const List<RoadReport> reports = [
    RoadReport(
      id: 'r1',
      title: 'Lubang besar di tengah jalan',
      address: 'Jl. Sudirman No. 45, Jakarta',
      description: 'Ada lubang yang cukup dalam dan membahayakan pengendara motor.',
      category: 'Jalan Rusak',
      latitude: -6.2088,
      longitude: 106.8456,
      severity: ReportSeverity.high,
      status: ReportStatus.pending,
      reportedAgo: '5m lalu',
      votes: 24,
    ),
    RoadReport(
      id: 'r2',
      title: 'Aspal retak panjang',
      address: 'Jl. Gatot Subroto, Jakarta',
      description: 'Retak parah di sisi kiri jalan sepanjang 5 meter.',
      category: 'Jalan Rusak',
      latitude: -6.2350,
      longitude: 106.8200,
      severity: ReportSeverity.medium,
      status: ReportStatus.inProgress,
      reportedAgo: '1j lalu',
      votes: 12,
    ),
    RoadReport(
      id: 'r3',
      title: 'Genangan air dalam',
      address: 'Jl. Thamrin, Jakarta Pusat',
      description: 'Drainase buruk membuat jalan tergenang sehabis hujan.',
      category: 'Banjir',
      latitude: -6.1950,
      longitude: 106.8230,
      severity: ReportSeverity.low,
      status: ReportStatus.fixed,
      reportedAgo: '3h lalu',
      votes: 8,
    ),
    RoadReport(
      id: 'r4',
      title: 'Trotoar hancur',
      address: 'Jl. Kuningan, Jakarta',
      description: 'Trotoar tidak bisa dilewati pejalan kaki karena material berserakan.',
      category: 'Trotoar Rusak',
      latitude: -6.2250,
      longitude: 106.8350,
      severity: ReportSeverity.medium,
      status: ReportStatus.pending,
      reportedAgo: '6j lalu',
      votes: 17,
    ),
  ];

  static const LatLng defaultCenter = LatLng(-6.2088, 106.8456);
}
