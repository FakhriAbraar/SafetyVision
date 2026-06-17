import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../theme/app_theme.dart';
import '../services/db_service.dart';

class ReportCard extends StatelessWidget {
  final RoadReport report;
  const ReportCard({super.key, required this.report});

  ({Color color, Color bg, String label}) get _severity {
    switch (report.severity) {
      case ReportSeverity.high:
        return (
          color: AppColors.danger,
          bg: const Color(0xFFFEE2E2),
          label: 'Parah',
        );
      case ReportSeverity.medium:
        return (
          color: AppColors.warning,
          bg: const Color(0xFFFEF3C7),
          label: 'Sedang',
        );
      case ReportSeverity.low:
        return (
          color: AppColors.success,
          bg: const Color(0xFFD1FAE5),
          label: 'Ringan',
        );
      case ReportSeverity.other:
        return (
          color: AppColors.textSecondary,
          bg: AppColors.divider.withValues(alpha: 0.2),
          label: 'Lainnya',
        );
    }
  }

  ({Color color, String label, IconData icon}) get _status {
    switch (report.status) {
      case ReportStatus.pending:
        return (
          color: AppColors.danger,
          label: 'Menunggu',
          icon: Icons.schedule_rounded,
        );
      case ReportStatus.inProgress:
        return (
          color: AppColors.warning,
          label: 'Diproses',
          icon: Icons.handyman_rounded,
        );
      case ReportStatus.fixed:
        return (
          color: AppColors.success,
          label: 'Selesai',
          icon: Icons.check_circle_rounded,
        );
    }
  }

  Widget _buildImage(Color color) {
    return FutureBuilder<List<String>>(
      future: DbService().fetchImages(report.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _imagePlaceholder(color);
        }
        
        final images = snapshot.data;
        if (images == null || images.isEmpty) {
          final path = report.imagePath;
          if (path != null && path.isNotEmpty && File(path).existsSync()) {
            return Image.file(
              File(path),
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => _imagePlaceholder(color),
            );
          }
          return _imagePlaceholder(color);
        }

        try {
          final bytes = base64Decode(images.first);
          return Image.memory(
            bytes,
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(color),
          );
        } catch (e) {
          return _imagePlaceholder(color);
        }
      },
    );
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 36,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sev = _severity;
    final st = _status;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sev.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: sev.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sev.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sev.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                report.reportedAgo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildImage(sev.color),
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  report.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(st.icon, size: 14, color: st.color),
              const SizedBox(width: 4),
              Text(
                st.label,
                style: TextStyle(
                  fontSize: 11,
                  color: st.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${report.votes}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
