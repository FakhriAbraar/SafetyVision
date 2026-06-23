import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'report_detail_sheet.dart';

class MapView extends StatefulWidget {
  final ReportStatus? filterStatus;
  final String? filterCategory;

  const MapView({
    super.key,
    this.filterStatus,
    this.filterCategory,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _lastCentered;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Pindahkan peta ke [target] setelah frame selesai, sekali per lokasi baru.
  void _recenterIfNeeded(LatLng target) {
    if (_lastCentered == target) return;
    _lastCentered = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(target, 15);
    });
  }

  Color _severityColor(ReportSeverity s) {
    switch (s) {
      case ReportSeverity.high:
        return AppColors.danger;
      case ReportSeverity.medium:
        return AppColors.warning;
      case ReportSeverity.low:
        return AppColors.success;
      case ReportSeverity.other:
        return AppColors.textSecondary;
    }
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:
        return AppColors.danger;
      case ReportStatus.inProgress:
        return AppColors.warning;
      case ReportStatus.fixed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).reports;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: StreamBuilder<List<RoadReport>>(
        stream: repo.watchReports(),
        initialData: const [],
        builder: (context, snapshot) {
          final allReports = snapshot.data ?? const <RoadReport>[];

          // Terapkan filter status dan kategori
          final reports = allReports.where((r) {
            if (widget.filterStatus != null && r.status != widget.filterStatus) {
              return false;
            }
            if (widget.filterCategory != null &&
                r.category != widget.filterCategory) {
              return false;
            }
            return true;
          }).toList();

          // Fokus ke laporan terbaru (paling depan), atau default bila kosong.
          final target =
              allReports.isNotEmpty ? allReports.first.location : DummyData.defaultCenter;
          _recenterIfNeeded(target);
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: DummyData.defaultCenter,
                  initialZoom: 13,
                  minZoom: 4,
                  maxZoom: 18,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safevision',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final r in reports)
                        Marker(
                          point: r.location,
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => showReportDetailSheet(context, r),
                            child: _ReportPin(
                              severityColor: _severityColor(r.severity),
                              statusColor: _statusColor(r.status),
                              isFixed: r.status == ReportStatus.fixed,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  children: [
                    _MapAction(
                      icon: Icons.my_location_rounded,
                      onTap: () => _mapController.move(target, 15),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reports.length == allReports.length
                            ? '${reports.length} laporan di sekitar'
                            : '${reports.length} dari ${allReports.length} laporan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportPin extends StatelessWidget {
  final Color severityColor;
  final Color statusColor;
  final bool isFixed;
  const _ReportPin({
    required this.severityColor,
    required this.statusColor,
    required this.isFixed,
  });

  @override
  Widget build(BuildContext context) {
    // Jika sudah diperbaiki: pin hijau dengan ikon centang.
    final pinColor = isFixed ? AppColors.success : severityColor;
    final icon = isFixed ? Icons.check_rounded : Icons.warning_rounded;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}


class _MapAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
