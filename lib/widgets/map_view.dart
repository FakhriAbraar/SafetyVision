import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  Color _severityColor(ReportSeverity s) {
    switch (s) {
      case ReportSeverity.high:
        return AppColors.danger;
      case ReportSeverity.medium:
        return AppColors.warning;
      case ReportSeverity.low:
        return AppColors.success;
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
          final reports = snapshot.data ?? const <RoadReport>[];
          return Stack(
            children: [
              FlutterMap(
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
                          child: _ReportPin(
                            severityColor: _severityColor(r.severity),
                            statusColor: _statusColor(r.status),
                          ),
                        ),
                      const Marker(
                        point: DummyData.defaultCenter,
                        width: 22,
                        height: 22,
                        child: _UserPin(),
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
                    _MapAction(icon: Icons.my_location_rounded, onTap: () {}),
                    const SizedBox(height: 8),
                    _MapAction(icon: Icons.layers_outlined, onTap: () {}),
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
                        '${reports.length} laporan di sekitar',
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
  const _ReportPin({required this.severityColor, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: severityColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: severityColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_rounded,
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

class _UserPin extends StatelessWidget {
  const _UserPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
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
