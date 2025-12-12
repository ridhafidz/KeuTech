import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'home_screen.dart'; // Pastikan file ini ada
import 'login_screen.dart'; // Pastikan file ini ada

// --- DEFINISI WARNA KHUSUS ---
const Color kPrimaryColor = Color(0xFF7B1FA2); 
const Color kCardBackground = Colors.white; 
const Color kInputFillColor = Color(0xFFF0F0F0); 
const Color kGradientStart = Color(0xFFE0B0FF); 
const Color kGradientEnd = Color(0xFFB39DDB); 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // <<< SUPABASE & CONTROLLER >>>
  final _formKey = GlobalKey<FormState>(); // <<< KEY UNTUK VALIDASI FORM
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Pastikan Supabase diinisialisasi di main.dart sebelum digunakan
  final supabase = Supabase.instance.client; 
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // <<< FUNGSI REGISTRASI DENGAN SUPABASE >>>
  Future<void> _signUp() async {
    // 1. Validasi form di sisi klien
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi gagal
    }
    
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _nameController.text.trim();
      
      // Panggil Supabase Sign Up
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        // Metadata tambahan yang akan disimpan di tabel auth.users
        data: {'full_name': fullName}, 
      );

      // Catatan: Supabase sekarang mengembalikan AuthResponse, bukan UserResponse
      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran Berhasil! Silakan cek email Anda untuk verifikasi (jika diaktifkan).')),
          );
          // Navigasi ke Login menggunakan named route
          Navigator.pushReplacementNamed(context, '/login'); 
        }
      } else if (response.session == null) {
         // Ini biasanya terjadi jika Email Confirmation diaktifkan.
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pendaftaran berhasil. Cek email Anda untuk link konfirmasi.')),
            );
            Navigator.pushReplacementNamed(context, '/login'); 
         }
      }
      
    } on AuthException catch (e) {
      if (mounted) {
        // Tampilkan error dari Supabase (misal: email sudah ada, password terlalu lemah)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Gagal: ${e.message}')),
        );
        // Debugging: Cetak pesan error Supabase ke konsol
        debugPrint('Supabase Auth Error: ${e.message}');
      }
    } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi kesalahan tak terduga.')),
          );
        }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Menggunakan bodySmall karena bodyMedium mungkin sudah tidak ada di versi Flutter/Dart terbaru
    final bodyTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'Poppins');
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundBlur(),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.1), 
                  Text('KeuTech', style: bodyTextStyle?.copyWith(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  SizedBox(height: screenHeight * 0.05),
                  
                  // BUNGKUS DENGAN FORM
                  Form(
                    key: _formKey, // <<< FORM KEY
                    child: _buildRegisterForm(context, bodyTextStyle!),
                  ),
                  
                  const Spacer(), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlur() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: kGradientStart.withOpacity(0.5)))),
          Positioned(bottom: -150, left: -150, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: kGradientEnd.withOpacity(0.5)))),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, TextStyle bodyTextStyle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            color: kCardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Buat Akun Baru', style: bodyTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Silakan daftar untuk melanjutkan', style: bodyTextStyle.copyWith(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),

              // Input Nama Lengkap (DENGAN VALIDATOR)
              Text('Nama Lengkap', style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildInputField(
                'Nama Lengkap Anda', 
                false, 
                _nameController,
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wajib diisi.';
                  }
                  return null;
                },
              ), 
              const SizedBox(height: 20),
              
              // Input Email (DENGAN VALIDATOR - Telah Diperbaiki)
              Text('Email', style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildInputField(
                'nama@email.com', 
                false, 
                _emailController,
                // --- VALIDATOR EMAIL YANG DIPERBAIKI (MENGGUNAKAN REGEX) ---
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email wajib diisi.';
                  }
                  // Regex dasar untuk validasi email
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'); 
                  
                  if (!emailRegex.hasMatch(value)) {
                    return 'Format alamat email tidak valid.'; 
                  }
                  return null;
                },
                // ---------------------------------------------------------
              ), 
              const SizedBox(height: 20),

              // Input Password (DENGAN VALIDATOR)
              Text('Password', style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildInputField(
                '********', 
                true, 
                _passwordController,
                (value) {
                  if (value == null || value.length < 6) {
                    // Supabase default minimal 6 karakter
                    return 'Password minimal 6 karakter.'; 
                  }
                  return null;
                },
              ), 
              
              const SizedBox(height: 20),

              // Tombol Daftar (DIHUBUNGKAN KE _signUp)
              _buildGradientButton(context, 'Daftar'),
              const SizedBox(height: 25),

              // Sudah Punya Akun?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun?', style: bodyTextStyle.copyWith(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      // Navigasi kembali ke halaman Login menggunakan named route
                      Navigator.popAndPushNamed(context, '/login'); 
                    },
                    child: Text('Masuk Sekarang', style: bodyTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk membuat TextFormField
  Widget _buildInputField(
    String hint, 
    bool isPassword, 
    TextEditingController controller,
    String? Function(String?) validator 
  ) {
    return TextFormField(
      controller: controller, 
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress, // Tambah tipe keyboard
      style: const TextStyle(fontFamily: 'Poppins'), 
      validator: validator, // Menerapkan validator
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins'),
        filled: true,
        fillColor: kInputFillColor,
        errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        // IconButton ini sekarang hanya placeholder, tidak memiliki fungsi show/hide password
        suffixIcon: isPassword ? const Icon(Icons.lock, color: Colors.grey) : null, 
      ),
    );
  }

  // Widget untuk membuat Tombol Gradasi
  Widget _buildGradientButton(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(colors: [kGradientStart, kGradientEnd], begin: Alignment.centerLeft, end: Alignment.centerRight),
        boxShadow: [BoxShadow(color: kGradientEnd.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signUp, // Panggil _signUp atau nonaktifkan saat loading
          borderRadius: BorderRadius.circular(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else
                Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              if (!_isLoading) const SizedBox(width: 8),
              if (!_isLoading) const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}