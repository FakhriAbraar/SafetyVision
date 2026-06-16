import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/road_report.dart';
import '../services/app_scope.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../screens/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: StreamBuilder<List<RoadReport>>(
                          stream: AppScope.of(context).reports.watchReports(),
                          initialData: const [],
                          builder: (context, snapshot) {
                            final reports =
                                snapshot.data ?? const <RoadReport>[];
                            final label = reports.isNotEmpty
                                ? reports.first.address
                                : 'Belum ada lokasi';
                            return Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const Text(
                    'SafeVision',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseAuth.instance.currentUser != null 
                  ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                  : const Stream.empty(),
              builder: (context, userSnapshot) {
                DateTime? lastNotifOpened;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data.containsKey('lastNotifOpened')) {
                    lastNotifOpened = (data['lastNotifOpened'] as Timestamp).toDate();
                  }
                }
                return StreamBuilder<List<RoadReport>>(
                  stream: AppScope.of(context).reports.watchReports(),
                  builder: (context, reportSnapshot) {
                    bool showNotifBadge = false;
                    final reports = reportSnapshot.data ?? [];
                    if (reports.isNotEmpty) {
                      final latestReport = reports.reduce((a, b) {
                        final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                        final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                        return aTime.isAfter(bTime) ? a : b;
                      });
                      final latestTime = latestReport.updatedAt ?? latestReport.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      if (lastNotifOpened == null || latestTime.isAfter(lastNotifOpened!)) {
                        showNotifBadge = true;
                      }
                    }
                    return _IconButton(
                      icon: Icons.notifications_outlined,
                      hasBadge: showNotifBadge,
                      onTap: () {
                        AuthService.updateLastNotifOpened();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: FutureBuilder<String?>(
                future: FirebaseAuth.instance.currentUser != null 
                    ? DbService().fetchProfilePicture(FirebaseAuth.instance.currentUser!.uid)
                    : Future.value(null),
                builder: (context, snapshot) {
                  final base64String = snapshot.data;
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider, width: 1.5),
                      image: base64String != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(base64String)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: base64String == null
                        ? const Icon(Icons.person_rounded, color: AppColors.textSecondary)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (hasBadge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
