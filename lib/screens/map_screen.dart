import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../theme/app_theme.dart';
import '../widgets/map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // null = tampilkan semua
  ReportStatus? _filterStatus;
  String? _filterCategory;

  static const _categories = [
    'Jalan Rusak',
    'Banjir',
    'Trotoar Rusak',
    'Lampu Mati',
    'Lainnya',
  ];

  /// Jumlah filter yang sedang aktif
  int get _activeFilterCount =>
      (_filterStatus != null ? 1 : 0) + (_filterCategory != null ? 1 : 0);

  void _openFilterSheet() {
    // Salin state sementara ke variabel lokal agar bisa dibatalkan
    ReportStatus? tempStatus = _filterStatus;
    String? tempCategory = _filterCategory;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    const Text(
                      'Filter Peta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (tempStatus != null || tempCategory != null)
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempStatus = null;
                            tempCategory = null;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Filter Status ──────────────────────────────────
                const Text(
                  'Status Laporan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      icon: Icons.layers_rounded,
                      selected: tempStatus == null,
                      color: AppColors.primary,
                      onTap: () => setSheetState(() => tempStatus = null),
                    ),
                    _FilterChip(
                      label: 'Menunggu',
                      icon: Icons.pending_rounded,
                      selected: tempStatus == ReportStatus.pending,
                      color: AppColors.danger,
                      onTap: () => setSheetState(
                          () => tempStatus = ReportStatus.pending),
                    ),
                    _FilterChip(
                      label: 'Diproses',
                      icon: Icons.engineering_rounded,
                      selected: tempStatus == ReportStatus.inProgress,
                      color: AppColors.warning,
                      onTap: () => setSheetState(
                          () => tempStatus = ReportStatus.inProgress),
                    ),
                    _FilterChip(
                      label: 'Sudah Diperbaiki',
                      icon: Icons.check_circle_rounded,
                      selected: tempStatus == ReportStatus.fixed,
                      color: AppColors.success,
                      onTap: () =>
                          setSheetState(() => tempStatus = ReportStatus.fixed),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Filter Kategori ────────────────────────────────
                const Text(
                  'Kategori Kerusakan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      icon: Icons.category_rounded,
                      selected: tempCategory == null,
                      color: AppColors.primary,
                      onTap: () =>
                          setSheetState(() => tempCategory = null),
                    ),
                    for (final cat in _categories)
                      _FilterChip(
                        label: cat,
                        icon: _categoryIcon(cat),
                        selected: tempCategory == cat,
                        color: AppColors.primary,
                        onTap: () =>
                            setSheetState(() => tempCategory = cat),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Tombol Terapkan ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterStatus = tempStatus;
                        _filterCategory = tempCategory;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Jalan Rusak':
        return Icons.warning_rounded;
      case 'Banjir':
        return Icons.water_rounded;
      case 'Trotoar Rusak':
        return Icons.directions_walk_rounded;
      case 'Lampu Mati':
        return Icons.lightbulb_rounded;
      default:
        return Icons.report_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Peta Laporan',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  // Tombol filter dengan badge jumlah filter aktif
                  GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFilterCount > 0
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: _activeFilterCount > 0
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _activeFilterCount > 0
                                ? 'Filter ($_activeFilterCount)'
                                : 'Filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: _activeFilterCount > 0
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Label filter aktif
            if (_filterStatus != null || _filterCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _buildActiveFilterLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterStatus = null;
                        _filterCategory = null;
                      }),
                      child: const Text(
                        'Hapus filter',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MapView(
                    filterStatus: _filterStatus,
                    filterCategory: _filterCategory,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _buildActiveFilterLabel() {
    final parts = <String>[];
    if (_filterStatus != null) {
      switch (_filterStatus!) {
        case ReportStatus.pending:
          parts.add('Status: Menunggu');
        case ReportStatus.inProgress:
          parts.add('Status: Diproses');
        case ReportStatus.fixed:
          parts.add('Status: Sudah Diperbaiki');
      }
    }
    if (_filterCategory != null) {
      parts.add('Kategori: $_filterCategory');
    }
    return parts.join('  •  ');
  }
}

// ── Chip filter ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}