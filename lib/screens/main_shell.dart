import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'upload_report_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'resolve_report_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onSeeMap: () => setState(() => _currentIndex = 1)),
    const MapScreen(),
    const SizedBox(), // placeholder — FAB opens modal
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _openReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadReportScreen(),
    );
  }

  void _openResolveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ResolveReportScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildScaffold(false, false);
    }
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isAdmin = false;
        DateTime? lastHistoryOpened;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (data?['role'] == 'admin') {
            isAdmin = true;
          }
          if (data != null && data.containsKey('lastHistoryOpened')) {
            lastHistoryOpened = (data['lastHistoryOpened'] as Timestamp).toDate();
          }
        }
        
        return StreamBuilder<List<RoadReport>>(
          stream: AppScope.of(context).reports.watchReports(),
          builder: (context, reportSnapshot) {
            bool showHistoryBadge = false;
            final reports = reportSnapshot.data ?? [];
            if (reports.isNotEmpty) {
              final latestReport = reports.reduce((a, b) {
                final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return aTime.isAfter(bTime) ? a : b;
              });
              final latestTime = latestReport.updatedAt ?? latestReport.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              if (lastHistoryOpened == null || latestTime.isAfter(lastHistoryOpened!)) {
                showHistoryBadge = true;
              }
            }
            return _buildScaffold(isAdmin, showHistoryBadge);
          },
        );
      },
    );
  }

  Widget _buildScaffold(bool isAdmin, bool showHistoryBadge) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        showHistoryBadge: showHistoryBadge,
        onTap: (index) {
          if (index == 2) {
            if (isAdmin) {
              _openResolveSheet();
            } else {
              _openReportSheet();
            }
            return;
          }
          if (index == 3) {
             AuthService.updateLastHistoryOpened();
          }
          setState(() => _currentIndex = index);
        },
        isAdmin: isAdmin,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;
  final bool showHistoryBadge;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.isAdmin,
    required this.showHistoryBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Peta',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _FABNavItem(
                onTap: () => onTap(2),
                isAdmin: isAdmin,
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                isActive: currentIndex == 3,
                showBadge: showHistoryBadge && currentIndex != 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _FABNavItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isAdmin;
  const _FABNavItem({required this.onTap, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isAdmin ? Icons.check_circle_rounded : Icons.add_rounded,
                  color: Colors.white, size: 26,
                ),
              ),
            ),
            Text(
              isAdmin ? 'Selesaikan' : 'Laporkan',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}