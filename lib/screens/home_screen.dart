import 'package:flutter/material.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/report_card.dart';
import '../widgets/stats_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    height: 260,
                    child: MapView(),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Laporan Terbaru',
                    actionLabel: 'Filter',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: StreamBuilder<List<RoadReport>>(
                  stream: AppScope.of(context).reports.watchReports(),
                  initialData: const [],
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? const <RoadReport>[];
                    if (reports.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Belum ada laporan. Jadilah yang pertama!',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ReportCard(report: reports[i]),
                    );
                  },
                ),
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
                    const Text(
                      'Halo, Warga 👋',
                      style: TextStyle(
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