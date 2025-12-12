import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
// Import file screens lainnya
import 'home_screen.dart'; 
import 'register_screen.dart'; 

// --- DEFINISI WARNA KHUSUS (SAMA) ---
const Color kPrimaryColor = Color(0xFF7B1FA2); 
const Color kCardBackground = Colors.white; 
const Color kInputFillColor = Color(0xFFF0F0F0); 
const Color kGradientStart = Color(0xFFE0B0FF); 
const Color kGradientEnd = Color(0xFFB39DDB); 

// Diubah menjadi StatefulWidget untuk state management
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // <<< SUPABASE & CONTROLLER >>>
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // <<< FUNGSI LOGIN DENGAN SUPABASE >>>
  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // Panggil Supabase Sign In
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!')),
        );
        // Navigasi ke Home menggunakan named route
        Navigator.pushReplacementNamed(context, '/home'); 
      }
      
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Gagal: ${e.message}')),
        );
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bodyTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins');

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
                  _buildLoginForm(context, bodyTextStyle!), 
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

  Widget _buildLoginForm(BuildContext context, TextStyle bodyTextStyle) {
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
              Text('Selamat Datang', style: bodyTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Silakan masuk ke akun Anda', style: bodyTextStyle.copyWith(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),

              // Input Email (Dihubungkan ke Controller)
              Text('Email', style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildInputField('nama@email.com', false, _emailController), 
              const SizedBox(height: 20),

              // Input Password (Dihubungkan ke Controller)
              Text('Password', style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildInputField('********', true, _passwordController), 
              
              // Lupa Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Lupa password?', style: bodyTextStyle.copyWith(color: kPrimaryColor)),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Masuk dengan Gradasi (Dihubungkan ke _signIn)
              _buildGradientButton(context, 'Masuk'), 
              const SizedBox(height: 25),

              // Daftar Sekarang
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun?', style: bodyTextStyle.copyWith(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      // Navigasi ke Register menggunakan named route
                      Navigator.pushNamed(context, '/register'); 
                    },
                    child: Text('Daftar Sekarang', style: bodyTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, bool isPassword, TextEditingController controller) {
    return TextFormField(
      controller: controller, 
      obscureText: isPassword,
      style: const TextStyle(fontFamily: 'Poppins'), 
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins'),
        filled: true,
        fillColor: kInputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: isPassword ? IconButton(icon: const Icon(Icons.visibility_off, color: Colors.grey), onPressed: () {}) : null,
      ),
    );
  }

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
          onTap: _isLoading ? null : _signIn, // Panggil _signIn atau nonaktifkan saat loading
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