import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keutech/screens/edit_profile_screen.dart';
import 'package:keutech/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const Color themeColor = Color(0xFFA694F6);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  late final User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _supabase.auth.currentUser;
    // Panggil _loadUserProfile saat widget dibuat
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      _isLoading = false;
    }
  }

  // FUNGSI UNTUK MEMUAT DATA PROFIL DARI TABEL "user_profiles"
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabase
          .from('user_profiles')
          .select('display_name, avatar_url')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load profile: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Getter untuk Nama Tampilan dan URL Avatar
  String get displayName =>
      _userProfile?['display_name'] ??
      _currentUser?.email?.split('@').first ??
      'User';
  String? get avatarUrl => _userProfile?['avatar_url'];
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  // Mendengarkan perubahan data dari EditProfileScreen
  void _navigateToEditProfile() async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    // Jika result true (profil berhasil diupdate), muat ulang data
    if (result == true) {
      setState(() => _isLoading = true);
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null) {
      return const Center(child: Text('Silakan login untuk melihat profil.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profil",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // =========== KARTU PROFIL ===========
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ProfileScreen.themeColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: ProfileScreen.themeColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // =========== TAMPILAN AVATAR ===========
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          hasAvatar ? NetworkImage(avatarUrl!) : null,
                      child: hasAvatar
                          ? null
                          : const Icon(
                              Icons.person_outline,
                              size: 32,
                              color: ProfileScreen.themeColor,
                            ),
                    ),
                    // =====================================
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName, // MENAMPILKAN NAMA LENGKAP
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ?? '-',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _navigateToEditProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Edit Profil",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // ===== BAGIAN STAT CARD DIHAPUS =====
              const SizedBox(height: 32), // Memberi jarak lebih sebelum Menu

              // =========== MENU ITEMS ===========
              _MenuItem(
                icon: Icons.person_outline,
                title: "Informasi Akun",
                onTap: _navigateToEditProfile,
              ),

              const _MenuItem(
                  icon: Icons.pie_chart_outline, title: "Kategori Kustom"),
              const _MenuItem(
                  icon: Icons.notifications_none, title: "Notifikasi"),
              const _MenuItem(
                  icon: Icons.security, title: "Keamanan & Privasi"),
              const _MenuItem(
                  icon: Icons.help_outline, title: "Bantuan & Dukungan"),

              const SizedBox(height: 16),

              // =========== LOGOUT BUTTON ===========
              GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.logout, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Keluar",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget _StatItem dan _Divider SUDAH DIHAPUS KARENA TIDAK DIPAKAI LAGI

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ProfileScreen.themeColor.withOpacity(0.15),
                  child: Icon(
                    widget.icon,
                    color: ProfileScreen.themeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
