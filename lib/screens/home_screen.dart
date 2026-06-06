import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/report_card.dart';
import '../widgets/report_detail_sheet.dart';
import '../widgets/stats_row.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onSeeMap;
  const HomeScreen({super.key, this.onSeeMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GreetingBanner(),
                  const SizedBox(height: 20),
                  const StatsRow(),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Peta Laporan',
                    actionLabel: 'Lihat semua',
                    onTap: onSeeMap ?? () {},
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    height: 260,
                    child: MapView(),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _RecentReports(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  String _greetingName() {
    final user = AuthService.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Warga';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_greetingName()} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lihat jalan rusak?\nLaporkan sekarang.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.accent,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+10 poin per laporan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _BannerArtwork(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE5D6), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ajak teman & dapatkan rewards menarik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerArtwork extends StatelessWidget {
  const _BannerArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 8,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.danger,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bagian "Laporan Terbaru": punya filter status (Semua/Aktif/Diproses/Selesai)
/// dan grid kartu yang bisa diketuk untuk membuka popup detail.
class _RecentReports extends StatefulWidget {
  const _RecentReports();

  @override
  State<_RecentReports> createState() => _RecentReportsState();
}

class _RecentReportsState extends State<_RecentReports> {
  // null = Semua
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Filter status (sesuai grid statistik di atas)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('Semua', null),
            _filterChip('Aktif', ReportStatus.pending),
            _filterChip('Diproses', ReportStatus.inProgress),
            _filterChip('Selesai', ReportStatus.fixed),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<RoadReport>>(
          stream: AppScope.of(context).reports.watchReports(),
          initialData: const [],
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <RoadReport>[];
            final reports = _filter == null
                ? all
                : all.where((r) => r.status == _filter).toList();
            if (reports.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Tidak ada laporan untuk filter ini.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 250,
              ),
              itemCount: reports.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => showReportDetailSheet(context, reports[i]),
                child: ReportCard(report: reports[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, ReportStatus? status) {
    final selected = _filter == status;
    return GestureDetector(
      onTap: () => setState(() => _filter = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}