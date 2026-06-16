import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoadReport>>(
      stream: AppScope.of(context).reports.watchReports(),
      initialData: const [],
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <RoadReport>[];
        final aktif = reports
            .where((r) => r.status == ReportStatus.pending)
            .length;
        final diproses = reports
            .where((r) => r.status == ReportStatus.inProgress)
            .length;
        final selesai = reports
            .where((r) => r.status == ReportStatus.fixed)
            .length;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.report_problem_rounded,
                iconColor: AppColors.danger,
                iconBg: const Color(0xFFFEE2E2),
                value: '$aktif',
                label: 'Aktif',
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.verified_rounded,
                iconColor: AppColors.success,
                iconBg: const Color(0xFFD1FAE5),
                value: '$selesai',
                label: 'Selesai',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
