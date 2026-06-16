import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/road_report.dart';
import '../services/db_service.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
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

  Future<String?> _fetchDisplayName(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['displayName'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _onRefresh() async {
    setState(() {}); // Memicu ulang FutureBuilder
  }

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

      String role = 'user';
      if (currentUser != null) {
        role = await AuthService.getUserRole(currentUser.uid);
      }

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.report.id)
          .collection('comments')
          .add({
        'text': text,
        'userName': userName, // Nama akun dinamis berdasarkan yang login
        'userId': currentUser?.uid, // Menyimpan UID untuk referensi data
        'role': role,
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        FutureBuilder<String?>(
                          future: report.userId != null ? DbService().fetchProfilePicture(report.userId!) : Future.value(null),
                          builder: (context, snapshot) {
                            final base64String = snapshot.data;
                            if (base64String != null && base64String.isNotEmpty) {
                              return Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: MemoryImage(base64Decode(base64String)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String?>(
                                future: _fetchDisplayName(report.userId),
                                builder: (context, snapshot) {
                                  final name = snapshot.data ?? (report.userName?.isNotEmpty == true ? report.userName! : 'Anonim');
                                  return Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  );
                                },
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                report.resolutionDescription?.isNotEmpty == true 
                                  ? report.resolutionDescription! 
                                  : 'Tim terkait telah menangani dan menyelesaikan masalah pada laporan ini. Berikut adalah bukti foto perbaikan yang telah dilakukan:',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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
                          final userId = data['userId'] as String?;
                          final role = data['role'] as String?;
                          final isAdmin = role == 'admin';
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                          final isMyComment = userId != null && userId == currentUserId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAdmin ? AppColors.primary.withValues(alpha: 0.05) : Colors.white, 
                                borderRadius: BorderRadius.circular(12), 
                                border: Border.all(color: isAdmin ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<String?>(
                                    future: userId != null ? DbService().fetchProfilePicture(userId) : Future.value(null),
                                    builder: (context, snapshot) {
                                      final base64String = snapshot.data;
                                      if (base64String != null && base64String.isNotEmpty) {
                                        return Container(
                                          width: 28, height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: MemoryImage(base64Decode(base64String)),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Icon(Icons.account_circle, color: AppColors.textMuted, size: 28);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            FutureBuilder<String?>(
                                              future: _fetchDisplayName(userId),
                                              builder: (context, snapshot) {
                                                final name = snapshot.data ?? userName;
                                                return Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));
                                              },
                                            ),
                                            if (isAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ]
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (isMyComment)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus Komentar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            content: const Text('Komentar ini akan dihapus secara permanen.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true), 
                                                child: const Text('Hapus', style: TextStyle(color: AppColors.danger))
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('reports')
                                                .doc(report.id)
                                                .collection('comments')
                                                .doc(doc.id)
                                                .delete();
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
                                            }
                                          }
                                        }
                                      },
                                    ),
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
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(filePaths: [path]),
                ));
              },
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: maxHeight),
                color: Colors.black,
                child: Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _photoPlaceholder()),
              ),
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
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(images: images, initialIndex: index),
                    ));
                  },
                  child: Stack(
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
                  ),
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
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(images: images, initialIndex: index),
                    ));
                  },
                  child: Stack(
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
                  ),
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

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images; // base64 strings
  final List<String> filePaths; // local paths
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    this.images = const [],
    this.filePaths = const [],
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final total = widget.images.isNotEmpty ? widget.images.length : widget.filePaths.length;
    if (_currentIndex < total - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.isNotEmpty ? widget.images.length : widget.filePaths.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: total,
            itemBuilder: (context, index) {
              try {
                Widget imgWidget;
                if (widget.images.isNotEmpty) {
                  final bytes = base64Decode(widget.images[index]);
                  imgWidget = Image.memory(bytes, fit: BoxFit.contain);
                } else {
                  imgWidget = Image.file(File(widget.filePaths[index]), fit: BoxFit.contain);
                }
                return InteractiveViewer(child: imgWidget);
              } catch (_) {
                return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64));
              }
            },
          ),
          if (total > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: MediaQuery.of(context).size.height / 2 - 24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 32),
                  onPressed: _prevPage,
                ),
              ),
            if (_currentIndex < total - 1)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height / 2 - 24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 32),
                  onPressed: _nextPage,
                ),
              ),
            Positioned(
              bottom: 32,
              left: 0, right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / $total',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}