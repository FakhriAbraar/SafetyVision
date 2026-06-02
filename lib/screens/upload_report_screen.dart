import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';

const String geminiApiKey = 'KEY_HERE';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  int _currentStep = 0; // 0=detail, 1=foto, 2=analisis, 3=lokasi
  bool _isAnalyzing = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedSeverity = 'Sedang';
  String _selectedCategory = 'Jalan Rusak';

  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 5) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _photos.add(image);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _submit() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Laporan berhasil dikirim!'),
          ],
        ),
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildSheetHandle(),
          _buildSheetHeader(),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _currentStep == 0
                  ? _buildStep1Detail()
                  : _currentStep == 1
                  ? _buildStep2Photo()
                  : _currentStep == 2
                  ? _buildStep3Analysis()
                  : _buildStep4Location(),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.report_problem_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat Laporan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('Bantu perbaiki infrastruktur kota',
                  style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Detail', 'Foto', 'Analisis', 'Lokasi'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : isActive
                            ? AppColors.primary
                            : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.circle,
                        size: isDone ? 14 : 8,
                        color: (isDone || isActive)
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < _currentStep
                          ? AppColors.success
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Detail ───────────────────────────────────────────
  Widget _buildStep1Detail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionLabel('Judul Laporan'),
        const SizedBox(height: 8),
        _buildTextInput(
          controller: _titleController,
          hint: 'Contoh: Lubang besar di Jl. Sudirman',
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Deskripsi'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText:
              'Deskripsikan kondisi jalan, ukuran kerusakan, risiko yang ditimbulkan...',
              hintStyle:
              TextStyle(color: AppColors.textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 2: Foto ─────────────────────────────────────────────
  Widget _buildStep2Photo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Upload zone
        GestureDetector(
          onTap: () => _pickPhoto(ImageSource.gallery),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded,
                      size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tambah foto kerusakan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Format JPG / PNG • Maks 10 MB per foto',
                  style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _photoSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () => _pickPhoto(ImageSource.camera),
                    ),
                    const SizedBox(width: 10),
                    _photoSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      filled: false,
                      onTap: () => _pickPhoto(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Counter
        Row(
          children: [
            Text(
              'Foto dipilih (${_photos.length}/5)',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (_photos.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _photos.clear()),
                child: const Text('Hapus semua',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.danger)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'Belum ada foto yang dipilih.\nFoto membantu petugas menangani lebih cepat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount:
            _photos.length < 5 ? _photos.length + 1 : 5,
            itemBuilder: (_, i) {
              if (i == _photos.length && _photos.length < 5) {
                return GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.gallery),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.divider, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: AppColors.textMuted, size: 24),
                        SizedBox(height: 4),
                        Text('Tambah',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photos[i].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 10, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 16),

        // Tip box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.lightbulb_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tips: Ambil foto dari sudut yang memperlihatkan keseluruhan kerusakan. Pastikan pencahayaan cukup.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _analyzePhotosWithAI() async {
    setState(() => _currentStep = 2); // Pindah ke tahap analisis langsung
    
    if (_photos.isEmpty) {
      return;
    }
    
    setState(() => _isAnalyzing = true);
    
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'kategori': Schema.string(description: 'Kategori masalah, contoh: Jalan Rusak, Banjir, Trotoar Rusak, Lampu Mati, Lainnya'),
              'keparahan': Schema.string(description: 'Tingkat keparahan: Ringan, Sedang, atau Parah'),
            },
          ),
        ),
      );

      final prompt = TextPart('Analisis foto kerusakan infrastruktur berikut. Tentukan kategori masalah dan tingkat keparahannya.');
      final imageParts = await Future.wait(_photos.map((file) async => DataPart('image/jpeg', await file.readAsBytes())));
      
      final content = [Content.multi([prompt, ...imageParts])];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        try {
          final data = jsonDecode(response.text!);
          if (data['kategori'] != null) {
            String cat = data['kategori'].toString();
            if (['Jalan Rusak', 'Banjir', 'Trotoar Rusak', 'Lampu Mati'].contains(cat)) {
              _selectedCategory = cat;
            } else {
              _selectedCategory = 'Lainnya';
            }
          }
          if (data['keparahan'] != null) {
             String sev = data['keparahan'].toString();
             if (['Ringan', 'Sedang', 'Parah'].contains(sev)) {
               _selectedSeverity = sev;
             }
          }
        } catch (e) {
          debugPrint('JSON parse error: $e');
        }
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // ─── Step 3: Hasil Analisis ───────────────────────────────────
  Widget _buildStep3Analysis() {
    final severities = ['Ringan', 'Sedang', 'Parah'];
    final categories = [
      'Jalan Rusak',
      'Banjir',
      'Trotoar Rusak',
      'Lampu Mati',
      'Lainnya'
    ];

    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('AI sedang menganalisis foto...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Hasil analisis AI berdasarkan foto Anda. Anda dapat menyesuaikannya jika kurang tepat.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Kategori (Terdeteksi)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Tingkat Keparahan (Terdeteksi)'),
        const SizedBox(height: 8),
        Row(
          children: severities.map((s) {
            final isSelected = _selectedSeverity == s;
            Color color;
            Color bgColor;
            switch (s) {
              case 'Ringan':
                color = AppColors.success;
                bgColor = const Color(0xFFD1FAE5);
                break;
              case 'Sedang':
                color = AppColors.warning;
                bgColor = const Color(0xFFFEF3C7);
                break;
              default:
                color = AppColors.danger;
                bgColor = const Color(0xFFFEE2E2);
            }
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSeverity = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: s != 'Parah' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? bgColor : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 4: Lokasi ───────────────────────────────────────────
  Widget _buildStep4Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionLabel('Lokasi Kejadian'),
        const SizedBox(height: 8),

        // Map placeholder
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded,
                        size: 48,
                        color: AppColors.success.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text('Peta Lokasi',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Lokasiku',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.location_on_rounded,
                    size: 36, color: AppColors.danger),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildTextInput(
          controller: TextEditingController(
              text: 'Jl. Sudirman No. 45, Jakarta Pusat'),
          hint: 'Cari alamat...',
          icon: Icons.search_rounded,
        ),

        const SizedBox(height: 16),
        _sectionLabel('Kecamatan / Kelurahan'),
        const SizedBox(height: 8),
        _buildTextInput(
          controller: TextEditingController(),
          hint: 'Contoh: Kec. Tanah Abang',
          icon: Icons.location_city_rounded,
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Poin Reward',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                    SizedBox(height: 2),
                    Text(
                      'Laporan ini akan memberimu +10 poin. Kumpulkan poin untuk hadiah menarik!',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 2),
                    Text('+10',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Bottom Actions ───────────────────────────────────────────
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0 && !_isAnalyzing)
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _currentStep = _currentStep - 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Kembali',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),
          if (_currentStep > 0 && !_isAnalyzing) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : () {
                if (_currentStep == 3) {
                  _submit();
                } else if (_currentStep == 1) {
                  _analyzePhotosWithAI();
                } else {
                  setState(() => _currentStep++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 3 ? 'Kirim Laporan' : 'Lanjut',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _currentStep == 3
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String label,
    bool filled = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color:
                filled ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: filled ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}