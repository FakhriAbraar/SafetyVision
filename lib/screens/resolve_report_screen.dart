import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';

class ResolveReportScreen extends StatefulWidget {
  const ResolveReportScreen({super.key});

  @override
  State<ResolveReportScreen> createState() => _ResolveReportScreenState();
}

class _ResolveReportScreenState extends State<ResolveReportScreen> {
  bool _isLoadingLocation = true;
  String? _errorMessage;
  ReportLocation? _currentLocation;
  List<RoadReport> _allActiveReports = [];
  
  // State Filter & Search
  String _searchQuery = '';
  ReportSeverity? _severityFilter;
  
  // State Tahap 2 (Form Penyelesaian)
  RoadReport? _selectedReport;
  final TextEditingController _resolutionDescController = TextEditingController();
  final List<XFile> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _resolutionDescController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      if (!mounted) return;

      final repo = AppScope.of(context).reports;
      final reports = await repo.watchReports().first;

      setState(() {
        _currentLocation = loc;
        _allActiveReports = reports.where((r) => r.status != ReportStatus.fixed).toList();
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi GPS: $e';
        _isLoadingLocation = false;
      });
    }
  }

  double _calculateDistance(RoadReport r) {
    if (_currentLocation == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentLocation!.latitude, _currentLocation!.longitude,
      r.latitude, r.longitude,
    );
  }

  List<RoadReport> get _filteredAndSortedReports {
    var filtered = _allActiveReports.where((r) {
      if (_severityFilter != null && r.severity != _severityFilter) return false;
      if (_searchQuery.isNotEmpty && !r.title.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => _calculateDistance(a).compareTo(_calculateDistance(b)));
    return filtered;
  }

  void _onReportTapped(RoadReport report) {
    final dist = _calculateDistance(report);
    if (dist > 50.0) {
      _showErrorDialog('Lokasi Terlalu Jauh', 'Anda harus berada dalam radius 50 meter untuk memilih laporan ini. (Jarak Anda: ${dist.toStringAsFixed(1)}m)');
      return;
    }

    setState(() {
      _selectedReport = report;
      _resolutionDescController.clear();
      _photos.clear();
    });
  }

  Future<void> _openCamera() async {
    if (_photos.length >= 5) return;
    final XFile? image = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (image != null) {
      setState(() => _photos.add(image));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger))),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.5, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String label, Color bg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedReport == null) return;
    
    final dist = _calculateDistance(_selectedReport!);
    if (dist > 50.0) {
      _showErrorDialog('Lokasi Terlalu Jauh', 'Anda harus berada dalam radius 50 meter untuk menyelesaikan laporan ini. (Jarak Anda: ${dist.toStringAsFixed(1)}m)');
      return;
    }

    if (_resolutionDescController.text.trim().isEmpty) {
      _showSnack('Silakan masukkan deskripsi perbaikan terlebih dahulu.', AppColors.warning, Icons.warning_amber_rounded);
      return;
    }

    if (_photos.isEmpty) {
      _showSnack('Silakan ambil minimal 1 foto bukti perbaikan.', AppColors.warning, Icons.warning_amber_rounded);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = AppScope.of(context).reports;
      final photoFiles = _photos.map((x) => File(x.path)).toList();
      await DbService().uploadResolvedImages(_selectedReport!.id, photoFiles);
      await repo.updateStatus(
        _selectedReport!.id, 
        ReportStatus.fixed, 
        resolutionDescription: _resolutionDescController.text.trim(),
      );

      if (!mounted) return;
      _showSnack('Laporan berhasil diselesaikan!', AppColors.success, Icons.check_circle_rounded);
      
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Gagal menyelesaikan laporan: $e', AppColors.danger, Icons.error_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.1),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _buildErrorState()
                    : (_selectedReport == null ? _buildListStage() : _buildFormStage()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup'),
          )
        ],
      ),
    );
  }

  Widget _buildListStage() {
    final reports = _filteredAndSortedReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pilih Laporan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari judul laporan...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Semua', null),
                const SizedBox(width: 8),
                _filterChip('Parah', ReportSeverity.high),
                const SizedBox(width: 8),
                _filterChip('Sedang', ReportSeverity.medium),
                const SizedBox(width: 8),
                _filterChip('Ringan', ReportSeverity.low),
                const SizedBox(width: 8),
                _filterChip('Lainnya', ReportSeverity.other),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: reports.isEmpty
              ? const Center(child: Text('Tidak ada laporan ditemukan.', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    final dist = _calculateDistance(r);
                    final isNear = dist <= 10.0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isNear ? AppColors.success.withValues(alpha: 0.5) : AppColors.divider),
                      ),
                      child: InkWell(
                        onTap: () => _onReportTapped(r),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: isNear ? AppColors.success.withValues(alpha: 0.1) : AppColors.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(isNear ? Icons.my_location_rounded : Icons.location_on_rounded, 
                                  color: isNear ? AppColors.success : AppColors.textMuted),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${dist.toStringAsFixed(1)}m | ${_getSeverityLabel(r.severity)}', 
                                      style: TextStyle(fontSize: 12, color: isNear ? AppColors.success : AppColors.textSecondary, fontWeight: isNear ? FontWeight.bold : FontWeight.normal)
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: isNear ? AppColors.success : AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getSeverityLabel(ReportSeverity s) {
    switch (s) {
      case ReportSeverity.high: return 'Parah';
      case ReportSeverity.medium: return 'Sedang';
      case ReportSeverity.low: return 'Ringan';
      case ReportSeverity.other: return 'Lainnya';
    }
  }

  Widget _filterChip(String label, ReportSeverity? severity) {
    final isSelected = _severityFilter == severity;
    return GestureDetector(
      onTap: () => setState(() => _severityFilter = severity),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFormStage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _selectedReport = null;
                  _resolutionDescController.clear();
                  _photos.clear();
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kirim Bukti Perbaikan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedReport!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_selectedReport!.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Deskripsi Perbaikan (Wajib)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resolutionDescController,
            maxLength: 250,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Jelaskan perbaikan yang telah dilakukan...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Foto Bukti Perbaikan (Wajib)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: _openCamera,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28),
                        SizedBox(height: 4),
                        Text('Ambil Foto', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                ..._photos.asMap().entries.map((e) {
                  final idx = e.key;
                  final file = e.value;
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(file.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(idx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Selesaikan Laporan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
