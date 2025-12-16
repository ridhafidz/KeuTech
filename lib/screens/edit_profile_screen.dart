import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Hapus: import 'dart:io';
// XFile (dari image_picker) dan uploadBinary (dari supabase)
// sudah menangani kebutuhan file secara cross-platform

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // GANTI: Menggunakan XFile untuk menangani file secara Cross-Platform (termasuk Web)
  XFile? _pickedFile;
  String? _avatarUrl; // URL avatar saat ini dari Supabase

  bool _loading = false;

  static const Color themeColor = Color(0xFFA694F6);

  // ================= INIT & LOAD PROFILE =================
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('user_profiles')
          .select('display_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _usernameController.text = profile?['display_name'] as String? ??
            user.email?.split('@').first ??
            '';
        _avatarUrl = profile?['avatar_url'] as String?;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load profile: $e');
        setState(() {
          _usernameController.text =
              supabase.auth.currentUser?.email?.split('@').first ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked != null) {
      setState(() {
        _pickedFile = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? newAvatarUrl = _avatarUrl;

      if (_pickedFile != null) {
        final fileName = '${user.id}';

        final imageBytes = await _pickedFile!.readAsBytes();
        final fileExtension = _pickedFile!.name.split('.').last;
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              imageBytes,
              fileOptions: FileOptions(
                  upsert: true, contentType: 'image/$fileExtension'),
            );

        final baseUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

        newAvatarUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      await supabase.from('user_profiles').upsert({
        'id': user.id,
        'display_name': _usernameController.text.trim(),
        'avatar_url': newAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (_passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      if (!mounted) return;

      // 4. Perbarui State Lokal
      setState(() {
        _avatarUrl = newAvatarUrl;
        _pickedFile = null; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );

      // Kembali ke ProfileScreen setelah berhasil simpan
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      _showSnackbar('Gagal update password: ${e.message}');
    } catch (e) {
      if (mounted) {
        _showSnackbar(
            'Gagal update profil: Cek koneksi atau Policy Supabase. Error: ${e.toString()}');
        debugPrint('Fatal Save Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: FutureBuilder<ImageProvider<Object>?>(
                  // **PERBAIKAN KRITIS 3: Menggunakan FutureBuilder untuk menangani XFile (asinkron)**
                  future: _resolveImageProvider(),
                  builder: (context, snapshot) {
                    final backgroundImage = snapshot.data;
                    final bool showDefaultIcon = (backgroundImage == null);

                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: themeColor.withAlpha(0x27),
                          backgroundImage: backgroundImage,
                          child: showDefaultIcon
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: themeColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: themeColor,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ... (Kode UI lainnya tetap sama)
            _label("Username"),
            TextField(
              controller: _usernameController,
              decoration: _inputDecoration("Masukkan username"),
            ),
            const SizedBox(height: 16),
            _label("Email"),
            TextField(
              enabled: false,
              decoration: _inputDecoration(user?.email ?? '-'),
            ),
            const SizedBox(height: 16),
            _label("Password Baru"),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration("Kosongkan jika tidak diganti"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // **Fungsi Pembantu Baru untuk Mendapatkan ImageProvider**
  Future<ImageProvider<Object>?> _resolveImageProvider() async {
    if (_pickedFile != null) {
      // Ambil byte data secara asinkron (kompatibel Web & Native)
      final bytes = await _pickedFile!.readAsBytes();
      return MemoryImage(bytes);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null; // Tampilkan ikon default
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
}
