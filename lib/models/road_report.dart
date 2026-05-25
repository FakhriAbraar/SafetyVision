import 'package:latlong2/latlong.dart';

enum ReportSeverity { low, medium, high }

enum ReportStatus { pending, inProgress, fixed }

class RoadReport {
  final String id;
  final String title;
  final String address;
  final LatLng location;
  final ReportSeverity severity;
  final ReportStatus status;
  final String reportedAgo;
  final int votes;

  const RoadReport({
    required this.id,
    required this.title,
    required this.address,
    required this.location,
    required this.severity,
    required this.status,
    required this.reportedAgo,
    required this.votes,
  });
}

class DummyData {
  static const List<RoadReport> reports = [
    RoadReport(
      id: 'r1',
      title: 'Lubang besar di tengah jalan',
      address: 'Jl. Sudirman No. 45, Jakarta',
      location: LatLng(-6.2088, 106.8456),
      severity: ReportSeverity.high,
      status: ReportStatus.pending,
      reportedAgo: '5m lalu',
      votes: 24,
    ),
    RoadReport(
      id: 'r2',
      title: 'Aspal retak panjang',
      address: 'Jl. Gatot Subroto, Jakarta',
      location: LatLng(-6.2350, 106.8200),
      severity: ReportSeverity.medium,
      status: ReportStatus.inProgress,
      reportedAgo: '1j lalu',
      votes: 12,
    ),
    RoadReport(
      id: 'r3',
      title: 'Genangan air dalam',
      address: 'Jl. Thamrin, Jakarta Pusat',
      location: LatLng(-6.1950, 106.8230),
      severity: ReportSeverity.low,
      status: ReportStatus.fixed,
      reportedAgo: '3h lalu',
      votes: 8,
    ),
    RoadReport(
      id: 'r4',
      title: 'Trotoar hancur',
      address: 'Jl. Kuningan, Jakarta',
      location: LatLng(-6.2250, 106.8350),
      severity: ReportSeverity.medium,
      status: ReportStatus.pending,
      reportedAgo: '6j lalu',
      votes: 17,
    ),
  ];

  static const LatLng defaultCenter = LatLng(-6.2088, 106.8456);
}
