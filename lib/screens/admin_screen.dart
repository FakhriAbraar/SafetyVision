import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DateTime _selectedEndDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Analitik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: StreamBuilder<List<RoadReport>>(
        stream: AppScope.of(context).reports.watchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Statistik Keseluruhan'),
                const SizedBox(height: 12),
                _buildStatCards(reports),
                const SizedBox(height: 32),
                _buildChartHeader(),
                const SizedBox(height: 16),
                _buildChart(reports),
                const SizedBox(height: 32),
                _buildSectionTitle('Top Area (Hotspot)'),
                const SizedBox(height: 16),
                _buildHotspots(reports),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartHeader() {
    final startDate = _selectedEndDate.subtract(const Duration(days: 6));
    final dateRangeText = '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(_selectedEndDate)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tren Laporan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  dateRangeText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  Widget _buildStatCards(List<RoadReport> reports) {
    int total = reports.length;
    int fixed = reports.where((r) => r.status == ReportStatus.fixed).length;
    int pending = reports.where((r) => r.status == ReportStatus.pending).length;

    return Row(
      children: [
        _statCard('Total', total.toString(), AppColors.primary),
        const SizedBox(width: 12),
        _statCard('Selesai', fixed.toString(), AppColors.success),
        const SizedBox(width: 12),
        _statCard('Pending', pending.toString(), AppColors.danger),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<RoadReport> reports) {
    final counts = List.filled(7, 0);
    final startOfEndDay = DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day);
    final startOfStartDay = startOfEndDay.subtract(const Duration(days: 6));

    for (var r in reports) {
      if (r.createdAt == null) continue;
      final reportDate = DateTime(r.createdAt!.year, r.createdAt!.month, r.createdAt!.day);
      
      if (reportDate.isAfter(startOfStartDay.subtract(const Duration(days: 1))) && 
          reportDate.isBefore(startOfEndDay.add(const Duration(days: 1)))) {
        final index = reportDate.difference(startOfStartDay).inDays;
        if (index >= 0 && index < 7) {
          counts[index]++;
        }
      }
    }

    List<FlSpot> spots = [];
    int maxVal = 0;
    for (int i = 0; i < 7; i++) {
      if (counts[i] > maxVal) maxVal = counts[i];
      spots.add(FlSpot(i.toDouble(), counts[i].toDouble()));
    }

    // Beri jarak di atas grafik agar garis tidak mentok ke atap kartesius
    double maxY = maxVal == 0 ? 5 : (maxVal + maxVal * 0.5).ceilToDouble();

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, left: 0, top: 24, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Matikan garis vertikal agar tidak terlalu ramai
            drawHorizontalLine: true,
            horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1, // Interval dinamis
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.divider.withValues(alpha: 0.8),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final date = startOfStartDay.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d MMM').format(date),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1.5),
              left: BorderSide.none,
              right: BorderSide.none,
              top: BorderSide.none,
            ),
          ),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspots(List<RoadReport> reports) {
    Map<String, int> areaCounts = {};
    for (var r in reports) {
      String area = r.address.split(',').first.trim();
      if (area.isEmpty) area = "Lokasi Tidak Diketahui";
      areaCounts[area] = (areaCounts[area] ?? 0) + 1;
    }

    var sortedAreas = areaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topAreas = sortedAreas.take(3).toList();

    if (topAreas.isEmpty) {
      return const Text('Belum ada data area.', style: TextStyle(color: AppColors.textMuted));
    }

    return Column(
      children: topAreas.asMap().entries.map((entry) {
        int index = entry.key;
        var area = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: index == 0 ? AppColors.primary.withValues(alpha: 0.5) : AppColors.divider),
            boxShadow: [
              if (index == 0) BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index == 0 ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: index == 0 ? AppColors.primary : AppColors.divider),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: index == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  area.key,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${area.value} Laporan',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}