import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _FAQ(
      q: 'Bagaimana cara melaporkan kerusakan jalan?',
      a: 'Tap tombol "Laporkan" (ikon +) di bagian bawah layar. Isi judul, deskripsi, ambil foto, lalu konfirmasi lokasi. AI kami akan otomatis menganalisis kategori dan tingkat keparahan.',
    ),
    _FAQ(
      q: 'Berapa lama laporan akan ditindaklanjuti?',
      a: 'Admin akan meninjau laporan dalam 1×24 jam. Waktu perbaikan aktual bergantung pada prioritas dan ketersediaan tim di lapangan. Kamu akan mendapat notifikasi saat statusnya berubah.',
    ),
    _FAQ(
      q: 'Apa fungsi tombol "Upvote" di laporan?',
      a: 'Upvote menandakan kamu setuju laporan tersebut penting dan perlu segera diperbaiki. Laporan dengan upvote lebih banyak akan diprioritaskan oleh admin.',
    ),
    _FAQ(
      q: 'Kenapa AI tidak bisa mendeteksi kategori foto saya?',
      a: 'Pastikan foto cukup terang dan menampilkan kerusakan dengan jelas. Foto yang buram, terlalu gelap, atau tidak relevan mungkin tidak terdeteksi dengan akurat.',
    ),
    _FAQ(
      q: 'Apakah data lokasi saya aman?',
      a: 'Lokasi yang dibagikan adalah lokasi kerusakan yang kamu foto, bukan lokasi rumah kamu. Data hanya digunakan untuk menampilkan marker di peta laporan.',
    ),
    _FAQ(
      q: 'Bagaimana cara menghapus laporan?',
      a: 'Buka detail laporan milikmu, lalu scroll ke bawah dan ketuk tombol "Hapus Laporan". Laporan hanya bisa dihapus oleh pemilik laporan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bantuan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ada yang bisa kami bantu?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan jawaban di FAQ atau hubungi tim kami langsung.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // FAQ
            const Text(
              'Pertanyaan Umum (FAQ)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _faqs.length,
              (i) => _FAQTile(faq: _faqs[i], index: i),
            ),
            const SizedBox(height: 28),

            // Hubungi Kami
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.phone_rounded,
                    iconColor: AppColors.success,
                    title: 'Telepon / WhatsApp',
                    subtitle: '+62 800-0000-0000',
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: '+62 800-0000-0000'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nomor disalin ke clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppColors.divider),
                  _ContactTile(
                    icon: Icons.email_rounded,
                    iconColor: AppColors.primary,
                    title: 'Email',
                    subtitle: 'safetyvision@gmail.com',
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: 'safetyvision@gmail.com'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email disalin ke clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Jam operasional: Senin–Jumat, 08.00–17.00 WIB',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}

// ── Widget FAQ Tile ────────────────────────────────────────────────────────────
class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  final int index;
  const _FAQTile({required this.faq, required this.index});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.faq.q,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),
                    Text(
                      widget.faq.a,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Contact Tile ───────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.primary)),
      trailing: const Icon(Icons.open_in_new_rounded,
          size: 16, color: AppColors.textMuted),
    );
  }
}
