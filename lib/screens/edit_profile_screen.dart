import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isLoadingPic = true;
  File? _selectedImage;
  String? _existingProfilePicBase64; // foto profil yang sudah tersimpan

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
    _loadPhoneNumber();
    _loadExistingPhoto();
  }

  Future<void> _loadExistingPhoto() async {
    if (_user == null) {
      setState(() => _isLoadingPic = false);
      return;
    }
    try {
      final pic = await DbService().fetchProfilePicture(_user!.uid);
      if (mounted) {
        setState(() {
          _existingProfilePicBase64 = pic;
          _isLoadingPic = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPic = false);
    }
  }

  Future<void> _loadPhoneNumber() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
      if (doc.exists && doc.data()!.containsKey('phoneNumber')) {
        setState(() {
          _phoneController.text = doc.data()!['phoneNumber'];
        });
      }
    } catch (e) {
      debugPrint('Error loading phone number: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Ubah Display Name
      if (_nameController.text.trim() != _user.displayName) {
        await _user.updateDisplayName(_nameController.text.trim());
      }

      // 2. Simpan Data Profil ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).set({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      // 3. Ubah Password jika diisi
      if (_newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          _showSnack('Masukkan password saat ini untuk mengubah password', AppColors.danger);
          setState(() => _isLoading = false);
          return;
        }
        
        // Re-authenticate
        AuthCredential credential = EmailAuthProvider.credential(
          email: _user.email!,
          password: _currentPasswordController.text,
        );
        
        await _user.reauthenticateWithCredential(credential);
        await _user.updatePassword(_newPasswordController.text);
      }

      // 4. Upload Foto Profil ke Neon DB
      if (_selectedImage != null) {
        await DbService().uploadProfilePicture(_user.uid, _selectedImage!);
      }

      if (!mounted) return;
      _showSnack('Profil berhasil diperbarui!', AppColors.success);
      Navigator.pop(context, true); // true = refresh profil
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack('Password saat ini salah.', AppColors.danger);
      } else {
        _showSnack('Gagal memperbarui profil: ${e.message}', AppColors.danger);
      }
    } catch (e) {
      _showSnack('Gagal memperbarui profil: $e', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : (_existingProfilePicBase64 != null
                                    ? DecorationImage(
                                        image: MemoryImage(
                                            base64Decode(_existingProfilePicBase64!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: _isLoadingPic
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2)
                              : (_selectedImage == null &&
                                      _existingProfilePicBase64 == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Username tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ubah Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Saat Ini',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
