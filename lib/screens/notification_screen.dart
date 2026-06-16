import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/road_report.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'report_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _roleFuture = AuthService.getUserRole(user!.uid);
    } else {
      _roleFuture = Future.value('user');
    }
  }

  Stream<List<RoadReport>> _getNotifications(String role) {
    if (user == null) return Stream.value([]);
    
    if (role == 'admin') {
      return FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snap) {
             final list = snap.docs.map((doc) => RoadReport.fromFirestore(doc)).toList();
             list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
             return list;
          });
    } else {
      return FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: user!.uid)
          .snapshots()
          .map((snap) {
             final list = snap.docs.map((doc) => RoadReport.fromFirestore(doc)).toList();
             list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
             return list;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _roleFuture,
        builder: (context, roleSnapshot) {
          if (roleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final role = roleSnapshot.data ?? 'user';
          
          return StreamBuilder<List<RoadReport>>(
            stream: _getNotifications(role),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              
              final reports = snapshot.data ?? [];
              
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: reports.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text(
                                    'Belum ada notifikasi baru.',
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
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return _buildNotificationCard(context, report, role);
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, RoadReport report, String role) {
    IconData iconData;
    Color iconColor;
    Color bgColor;
    String title;
    String description;

    if (role == 'admin') {
      iconData = Icons.add_location_alt_rounded;
      iconColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.1);
      title = 'Laporan Baru Masuk';
      description = 'Laporan "${report.title}" telah dibuat oleh ${report.userName ?? 'Warga'}.';
    } else {
      if (report.status == ReportStatus.fixed) {
        iconData = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        title = 'Laporan Selesai Ditangani';
        description = 'Jalan rusak pada "${report.title}" telah selesai diperbaiki. Terima kasih!';
      } else {
        iconData = Icons.info_outline_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        title = 'Laporan Berhasil Dibuat';
        description = 'Laporan Anda "${report.title}" telah diterima dan sedang menunggu penanganan.';
      }
    }

    final time = report.createdAt ?? DateTime.now();
    final timeString = "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(report: report),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
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
                        description,
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
