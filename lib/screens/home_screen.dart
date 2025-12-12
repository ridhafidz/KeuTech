import 'dart:ui';
import 'package:flutter/material.dart';
import 'add_transaction_popup.dart';
import '/nav/custom_bottom_nav.dart'; // ← tambahkan ini

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // ← Rekap = index 0

  bool _showBalance = true;

  final List<String> _accounts = ['Cash', 'Tabungan', 'Bank', 'Dompet Digital'];

  final Map<String, int> _balances = {
    'Cash': 4800000,
    'Tabungan': 3000000,
    'Bank': 3000000,
    'Dompet Digital': 1500000,
  };

  final List<IconData> _accountIcons = [
    Icons.money,
    Icons.savings,
    Icons.account_balance,
    Icons.wallet,
  ];

  final Color _accountIconColor = const Color(0xFFA78BFA);

  String _formatCurrency(int value) {
    final s = value.toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  int get totalSaldo => _balances.values.fold(0, (a, b) => a + b);

  Widget _buildRekapPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo! 👋',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selamat datang kembali',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // ================= TOTAL SALDO =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFB79CFF), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Saldo',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showBalance ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed:
                          () => setState(() => _showBalance = !_showBalance),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _showBalance
                      ? 'Rp ${_formatCurrency(totalSaldo)}'
                      : '****************',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'Diperbarui hari ini',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= CHART DIPINDAH KE SINI =================
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: Text('Chart Area (dummy)')),
          ),

          const SizedBox(height: 20),

          // ================= INFO CARD ROW DIPINDAH KE BAWAH CHART =================
          Row(
            children: [
              _infoCard(
                title: 'Pemasukan',
                amount: 'Rp 8.5jt',
                percent: '+12% dari bulan lalu',
                isUp: true,
              ),
              const SizedBox(width: 12),
              _infoCard(
                title: 'Pengeluaran',
                amount: 'Rp 4.2jt',
                percent: '-5% dari bulan lalu',
                isUp: false,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= GRID SALDO DIPINDAH KE PALING BAWAH =================
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: _accounts.length,
            itemBuilder: (context, i) {
              final name = _accounts[i];
              final bal = _balances[name] ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _accountIconColor.withOpacity(0.12),
                      child: Icon(_accountIcons[i], color: _accountIconColor),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_formatCurrency(bal)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================ MAIN BUILD ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildRekapPage(),

      // ===================== CUSTOM BOTTOM NAV =====================
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i != 0) return; // halaman lain blm dibuat
          setState(() => _currentIndex = i);
        },
      ),

      // =================== FAB + POPUP =====================
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFA78BFA),
          child: const Icon(Icons.add, size: 28),
          onPressed: () async {
            final result = await showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Tutup Popup',
              barrierColor: Colors.black.withOpacity(0.4),
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, __, ___) => const SizedBox(),
              transitionBuilder: (context, animation, _, __) {
                final tween = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic));

                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(color: Colors.black26),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: animation.drive(tween),
                      child: const AddTransactionPopup(),
                    ),
                  ],
                );
              },
            );

            if (result is Map) {
              final int tab = result['tab'] ?? 0;
              final int amount = result['amount'] ?? 0;
              final int src = result['sourceIndex'] ?? -1;
              final int dst = result['destinationIndex'] ?? -1;

              setState(() {
                if (tab == 1) {
                  if (dst >= 0) {
                    _balances[_accounts[dst]] =
                        (_balances[_accounts[dst]] ?? 0) + amount;
                  }
                } else {
                  if (src >= 0) {
                    _balances[_accounts[src]] =
                        (_balances[_accounts[src]] ?? 0) - amount;
                  }
                }
              });
            }
          },
        ),
      ),
    );
  }

  // ======================= INFO CARD ======================
  Widget _infoCard({
    required String title,
    required String amount,
    required String percent,
    required bool isUp,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      isUp ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    isUp ? Icons.trending_up : Icons.trending_down,
                    color: isUp ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              percent,
              style: TextStyle(
                color: isUp ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
