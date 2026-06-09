import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/road_report.dart';
import '../services/db_service.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

Color reportSeverityColor(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.high: return AppColors.danger;
    case ReportSeverity.medium: return AppColors.warning;
    case ReportSeverity.low: return AppColors.success;
  }
}

String reportSeverityLabel(ReportSeverity s) {
  switch (s) {
    case ReportSeverity.high: return 'Parah';
    case ReportSeverity.medium: return 'Sedang';
    case ReportSeverity.low: return 'Ringan';
  }
}

Color reportStatusColor(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending: return AppColors.danger;
    case ReportStatus.inProgress: return AppColors.warning;
    case ReportStatus.fixed: return AppColors.success;
  }
}

String reportStatusLabel(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending: return 'Belum Ditangani';
    case ReportStatus.inProgress: return 'Sedang Diperbaiki';
    case ReportStatus.fixed: return 'Sudah Diperbaiki';
  }
}

class ReportDetailScreen extends StatefulWidget {
  final RoadReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late ReportStatus _status = widget.report.status;
  bool _updating = false;

  final TextEditingController _commentController = TextEditingController();

  RoadReport get report => widget.report;

  Future<void> _setStatus(ReportStatus status) async {
    if (status == _status || _updating) return;
    setState(() {
      _status = status;
      _updating = true;
    });
    try {
      await AppScope.of(context).reports.updateStatus(report.id, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _handleUpvote() async {
    try {
      await AppScope.of(context).reports.upvoteReport(report.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil memberikan upvote!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal melakukan upvote: $e')),
      );
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Menutup keyboard

    try {
      // Ambil data user yang sedang login saat ini dari Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;

      String userName = 'Warga';
      if (currentUser != null) {
        if (currentUser.displayName != null && currentUser.displayName!.trim().isNotEmpty) {
          userName = currentUser.displayName!;
        } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          // Jika displayName kosong, gunakan username dari email (sebelum tanda @)
          userName = currentUser.email!.split('@')[0];
        }
      }

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.report.id)
          .collection('comments')
          .add({
        'text': text,
        'userName': userName, // Nama akun dinamis berdasarkan yang login
        'userId': currentUser?.uid, // Menyimpan UID untuk referensi data
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixed = _status == ReportStatus.fixed;
    final statusColor = reportStatusColor(_status);
    final statusLabel = reportStatusLabel(_status);
    final severityColor = reportSeverityColor(report.severity);
    final severityLabel = reportSeverityLabel(report.severity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Gambar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildPhoto(MediaQuery.of(context).size.height * 0.4),
                    ),
                  ),

                  // 2. Info Judul & Severity
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        _badge(label: severityLabel, color: severityColor, icon: Icons.priority_high_rounded),
                      ],
                    ),
                  ),

                  // 3. Status Saat Ini
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _badge(
                      label: statusLabel,
                      color: statusColor,
                      icon: isFixed ? Icons.check_circle_rounded : Icons.build_circle_rounded,
                      filled: true,
                    ),
                  ),

                  // 4. Info Pelapor & Waktu & Upvote
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (report.userName?.isNotEmpty == true) ? report.userName! : 'Anonim',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(report.reportedAgo, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        // Tombol Upvote fungsional
                        ElevatedButton.icon(
                          onPressed: _handleUpvote,
                          icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                          label: Text('${report.votes}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. Lokasi Alamat & Deskripsi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 20, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
                              Text('${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 12),
                              const Text('Deskripsi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                report.description,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // Tambahan Balasan Admin Jika Sudah Selesai
                  if (isFixed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Balasan Admin: Perbaikan Selesai',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Tim terkait telah menangani dan menyelesaikan masalah pada laporan ini. Berikut adalah bukti foto perbaikan yang telah dilakukan:',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildResolvedPhotos(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 6. Bagian Komentar
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Komentar Diskusi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reports')
                        .doc(report.id)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Gagal memuat komentar.', style: TextStyle(color: AppColors.danger)),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('Belum ada komentar. Jadilah yang pertama berkomentar!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final text = data['text'] ?? '';
                          final userName = data['userName'] ?? 'Warga';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.account_circle, color: AppColors.textMuted, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 7. Input Komentar di Bagian Bawah
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPhoto(double maxHeight) {
    return FutureBuilder<List<String>>(
      future: DbService().fetchImages(report.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: maxHeight,
            width: double.infinity,
            color: AppColors.divider.withValues(alpha: 0.2),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final images = snapshot.data;
        if (images == null || images.isEmpty) {
          final path = report.imagePath;
          if (path != null && path.isNotEmpty && File(path).existsSync()) {
            return Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxHeight),
              color: Colors.black,
              child: Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _photoPlaceholder()),
            );
          }
          return _photoPlaceholder();
        }

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          color: Colors.black,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              try {
                final bytes = base64Decode(images[index]);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              } catch (e) {
                return _photoPlaceholder();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildResolvedPhotos(double maxHeight) {
    return FutureBuilder<List<String>>(
      future: DbService().fetchResolvedImages(report.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: maxHeight,
            width: double.infinity,
            color: AppColors.success.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator(color: AppColors.success)),
          );
        }

        final images = snapshot.data;
        if (images == null || images.isEmpty) {
          return Container(
            height: maxHeight, width: double.infinity, color: AppColors.success.withValues(alpha: 0.1),
            child: const Center(child: Text('Tidak ada foto bukti', style: TextStyle(color: AppColors.success))),
          );
        }

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          color: Colors.black,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              try {
                final bytes = base64Decode(images[index]);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              } catch (e) {
                return _photoPlaceholder();
              }
            },
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 200, width: double.infinity, color: AppColors.divider.withValues(alpha: 0.4),
      child: const Center(child: Icon(Icons.image_not_supported_rounded, size: 40, color: AppColors.textMuted)),
    );
  }

  Widget _badge({required String label, required Color color, required IconData icon, bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: filled ? Colors.white : color)),
        ],
      ),
    );
  }
}