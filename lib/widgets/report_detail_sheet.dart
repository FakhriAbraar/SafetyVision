import 'dart:io';

import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../services/report_repository.dart';
import '../theme/app_theme.dart';

Color reportSeverityColor(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.high:
      return AppColors.danger;
    case ReportSeverity.medium:
      return AppColors.warning;
    case ReportSeverity.low:
      return AppColors.success;
  }
}

String reportSeverityLabel(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.high:
      return 'Parah';
    case ReportSeverity.medium:
      return 'Sedang';
    case ReportSeverity.low:
      return 'Ringan';
  }
}

Color reportStatusColor(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending:
      return AppColors.danger;
    case ReportStatus.inProgress:
      return AppColors.warning;
    case ReportStatus.fixed:
      return AppColors.success;
  }
}

String reportStatusLabel(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending:
      return 'Belum Ditangani';
    case ReportStatus.inProgress:
      return 'Sedang Diperbaiki';
    case ReportStatus.fixed:
      return 'Sudah Diperbaiki';
  }
}

/// Tampilkan popup detail laporan (dipakai di peta & grid laporan terbaru).
void showReportDetailSheet(BuildContext context, RoadReport report) {
  final repo = AppScope.of(context).reports;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ReportDetailSheet(report: report, repo: repo),
  );
}

/// Bottom sheet detail laporan: foto (path lokal HP) + pelapor + lokasi + status.
class ReportDetailSheet extends StatefulWidget {
  final RoadReport report;
  final ReportRepository repo;

  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.repo,
  });

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  late ReportStatus _status = widget.report.status;
  bool _updating = false;
  bool _isAdmin = false;

  RoadReport get report => widget.report;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final role = await AuthService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _isAdmin = (role == 'admin');
        });
      }
    }
  }

  Future<void> _setStatus(ReportStatus status) async {
    if (status == _status || _updating) return;
    setState(() {
      _status = status;
      _updating = true;
    });
    try {
      await widget.repo.updateStatus(report.id, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixed = _status == ReportStatus.fixed;
    final statusColor = reportStatusColor(_status);
    final statusLabel = reportStatusLabel(_status);
    final severityColor = reportSeverityColor(report.severity);
    final severityLabel = reportSeverityLabel(report.severity);
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto dari path lokal HP (porsi besar, portrait, tidak terpotong)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildPhoto(screenHeight * 0.55),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                report.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _badge(
                              label: severityLabel,
                              color: severityColor,
                              icon: Icons.priority_high_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status (centang hijau bila sudah diperbaiki)
                        _badge(
                          label: statusLabel,
                          color: statusColor,
                          icon: isFixed
                              ? Icons.check_circle_rounded
                              : Icons.build_circle_rounded,
                          filled: true,
                        ),
                        const SizedBox(height: 16),
                        // Ubah status laporan (tersimpan ke Firestore)
                        if (_isAdmin) ...[
                          Row(
                            children: [
                              const Text(
                                'Ubah Status',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              if (_updating)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _statusOption(ReportStatus.pending, 'Aktif'),
                              const SizedBox(width: 8),
                              _statusOption(ReportStatus.inProgress, 'Diproses'),
                              const SizedBox(width: 8),
                              _statusOption(ReportStatus.fixed, 'Selesai'),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Pelapor (user yang upload)
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dilaporkan oleh',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted),
                                  ),
                                  Text(
                                    (report.userName != null &&
                                            report.userName!.isNotEmpty)
                                        ? report.userName!
                                        : 'Anonim',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Lokasi
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              report.reportedAgo,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            const Icon(Icons.thumb_up_alt_outlined,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${report.votes}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusOption(ReportStatus status, String label) {
    final selected = _status == status;
    final color = reportStatusColor(status);
    return Expanded(
      child: GestureDetector(
        onTap: _updating ? null : () => _setStatus(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(double maxHeight) {
    final path = report.imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.black,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => _photoPlaceholder(),
        ),
      );
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 240,
      width: double.infinity,
      color: AppColors.divider.withValues(alpha: 0.4),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded,
              size: 40, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('Foto tidak tersedia',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color color,
    required IconData icon,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
