import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'report_detail_screen.dart';

enum LogType { newReport, statusUpdate, fixedReport }

/// Model data internal untuk menampung baris log aktivitas
class ActivityLogItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final LogType type;
  final RoadReport report;

  ActivityLogItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.report,
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Helper untuk mendapatkan kecocokan waktu lokal secara akurat
  DateTime _getReportDateTime(RoadReport report) {
    if (report.createdAt != null) return report.createdAt!;

    // Fallback khusus untuk data dummy awal agar terdistribusi di hari yang berbeda
    final now = DateTime.now();
    if (report.id == 'r1') return now.subtract(const Duration(minutes: 5));
    if (report.id == 'r2') return now.subtract(const Duration(hours: 1));
    if (report.id == 'r4') return now.subtract(const Duration(hours: 6));
    if (report.id == 'r3') return now.subtract(const Duration(days: 3));
    return now;
  }

  /// Menentukan label kelompok berdasarkan selisih hari kalender
  String _getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Hari Ini';
    } else if (compareDate == yesterday) {
      return 'Kemarin';
    } else if (compareDate == twoDaysAgo) {
      return '2 Hari yang Lalu';
    } else if (compareDate == threeDaysAgo) {
      return '3 Hari yang Lalu';
    } else {
      return 'Lebih Lama';
    }
  }

  /// Memproses list RoadReport mentah menjadi list objek log aktivitas yang terurut
  List<ActivityLogItem> _generateLogs(List<RoadReport> reports) {
    final List<ActivityLogItem> logs = [];

    for (var report in reports) {
      final baseTime = _getReportDateTime(report);

      // 1. Setiap laporan pasti memiliki log "Laporan Baru"
      logs.add(ActivityLogItem(
        title: 'Laporan Baru Ditambahkan',
        description: 'Laporan "${report.title}" telah dibuat di ${report.address}.',
        timestamp: baseTime,
        type: LogType.newReport,
        report: report,
      ));

      // 2. Log simulasi perubahan status berdasarkan status terkini di database/repository
      if (report.status == ReportStatus.inProgress) {
        logs.add(ActivityLogItem(
          title: 'Status Laporan Diperbarui',
          description: 'Laporan "${report.title}" kini sedang dalam proses perbaikan.',
          timestamp: baseTime.add(const Duration(minutes: 30)),
          type: LogType.statusUpdate,
          report: report,
        ));
      } else if (report.status == ReportStatus.fixed) {
        logs.add(ActivityLogItem(
          title: 'Laporan Selesai Ditangani',
          description: 'Jalan rusak pada "${report.title}" telah selesai diperbaiki. Terima kasih!',
          timestamp: baseTime.add(const Duration(hours: 2)),
          type: LogType.fixedReport,
          report: report,
        ));
      }
    }

    // Urutkan seluruh log dari yang paling baru/gregorian tertinggi
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Mengelompokkan log ke dalam Map terurut berdasarkan label harinya
  Map<String, List<ActivityLogItem>> _groupLogs(List<ActivityLogItem> logs) {
    final Map<String, List<ActivityLogItem>> grouped = LinkedHashMap();

    // Inisialisasi urutan grup agar rapi dari hari ini ke bawah
    final sections = ['Hari Ini', 'Kemarin', '2 Hari yang Lalu', '3 Hari yang Lalu', 'Lebih Lama'];
    for (var section in sections) {
      grouped[section] = [];
    }

    for (var log in logs) {
      final label = _getGroupLabel(log.timestamp);
      if (grouped.containsKey(label)) {
        grouped[label]!.add(log);
      } else {
        grouped[label] = [log];
      }
    }

    // Bersihkan grup yang kosong agar tidak memakan space di UI
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Log Aktivitas Sistem',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<RoadReport>>(
        stream: AppScope.of(context).reports.watchReports(),
        initialData: const [],
        builder: (context, snapshot) {
          final allReports = snapshot.data ?? const <RoadReport>[];
          final allLogs = _generateLogs(allReports);
          final groupedLogs = _groupLogs(allLogs);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: allLogs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt_rounded, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada riwayat aktivitas log.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: groupedLogs.length,
            itemBuilder: (context, index) {
              final groupKey = groupedLogs.keys.elementAt(index);
              final logsInGroup = groupedLogs[groupKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Kelompok Waktu (Hari ini, Kemarin, dll)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      groupKey,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  // List item log di dalam kelompok tersebut
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: logsInGroup.length,
                    itemBuilder: (context, logIndex) {
                      final log = logsInGroup[logIndex];
                      return _buildLogCard(context, log);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, ActivityLogItem log) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    // Menentukan style dekorasi icon sesuai tipe event log
    switch (log.type) {
      case LogType.newReport:
        iconData = Icons.add_location_alt_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        break;
      case LogType.statusUpdate:
        iconData = Icons.engineering_rounded;
        iconColor = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case LogType.fixedReport:
        iconData = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
    }

    final timeString = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Berpindah ke detail report penuh saat item log ditekan
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(report: log.report),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indikator Icon Samping
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Deskripsi Konten Log
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}