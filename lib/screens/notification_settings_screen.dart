import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  // State untuk setiap toggle
  bool _notifLaporanBaru = true;
  bool _notifStatusUpdate = true;
  bool _notifUpvote = false;
  bool _notifPengumuman = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final settings =
            doc.data()!['notificationSettings'] as Map<String, dynamic>?;
        if (settings != null) {
          setState(() {
            _notifLaporanBaru = settings['laporanBaru'] as bool? ?? true;
            _notifStatusUpdate = settings['statusUpdate'] as bool? ?? true;
            _notifUpvote = settings['upvote'] as bool? ?? false;
            _notifPengumuman = settings['pengumuman'] as bool? ?? true;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({
        'notificationSettings': {
          'laporanBaru': _notifLaporanBaru,
          'statusUpdate': _notifStatusUpdate,
          'upvote': _notifUpvote,
          'pengumuman': _notifPengumuman,
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'laporanBaru':
          _notifLaporanBaru = value;
        case 'statusUpdate':
          _notifStatusUpdate = value;
        case 'upvote':
          _notifUpvote = value;
        case 'pengumuman':
          _notifPengumuman = value;
      }
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Atur jenis notifikasi yang ingin kamu terima dari SafeVision.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grup: Aktivitas Laporan
                  _SectionLabel(label: 'Aktivitas Laporan'),
                  const SizedBox(height: 10),
                  _SettingCard(
                    children: [
                      _ToggleItem(
                        icon: Icons.add_alert_rounded,
                        iconColor: AppColors.primary,
                        title: 'Laporan Baru',
                        subtitle: 'Notifikasi saat ada laporan baru masuk',
                        value: _notifLaporanBaru,
                        onChanged: (v) => _toggle('laporanBaru', v),
                      ),
                      _Divider(),
                      _ToggleItem(
                        icon: Icons.update_rounded,
                        iconColor: AppColors.warning,
                        title: 'Pembaruan Status',
                        subtitle:
                            'Notifikasi saat status laporanmu berubah',
                        value: _notifStatusUpdate,
                        onChanged: (v) => _toggle('statusUpdate', v),
                      ),
                      _Divider(),
                      _ToggleItem(
                        icon: Icons.thumb_up_rounded,
                        iconColor: AppColors.success,
                        title: 'Upvote Diterima',
                        subtitle:
                            'Notifikasi saat laporanmu mendapat dukungan',
                        value: _notifUpvote,
                        onChanged: (v) => _toggle('upvote', v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grup: Umum
                  _SectionLabel(label: 'Umum'),
                  const SizedBox(height: 10),
                  _SettingCard(
                    children: [
                      _ToggleItem(
                        icon: Icons.campaign_rounded,
                        iconColor: AppColors.accent,
                        title: 'Pengumuman',
                        subtitle: 'Info dan pengumuman dari tim SafeVision',
                        value: _notifPengumuman,
                        onChanged: (v) => _toggle('pengumuman', v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Komponen pembantu ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 64, color: AppColors.divider);
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
