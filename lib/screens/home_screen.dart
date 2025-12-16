import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keutech/models/transaction_model.dart';
import 'package:keutech/models/target_model.dart';
import 'package:keutech/screens/catatan_screen.dart';
import 'add_transaction_popup.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/weekly_chart.dart';
import 'package:keutech/screens/kalender_screen.dart';
import 'profile_screen.dart';

// --- STRUKTUR DATA UTAMA ---
class AccountData {
  final int id;
  final String name;
  final IconData icon;

  AccountData({required this.id, required this.name, required this.icon});
}

class CategoryData {
  final int id;
  final String name;
  final String type;

  CategoryData({required this.id, required this.name, required this.type});
}

// Class bantuan untuk menampung statistik bulanan
class MonthlyStats {
  final int currentMonthTotal;
  final double percentageChange;
  final bool isGrowthPositive;

  MonthlyStats({
    required this.currentMonthTotal,
    required this.percentageChange,
    required this.isGrowthPositive,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showBalance = true;
  final supabase = Supabase.instance.client;
  DateTime? targetUntil;
  bool _isLoading = true;
  List<AccountData> _accountList = [];
  Map<int, int> _balances = {};
  List<CategoryData> _categoryList = [];
  List<TransactionModel> transactions = [];
  TargetModel? _singleIncomeTarget;

  // Variabel untuk kompatibilitas
  List<TargetModel> targets = [];
  TargetModel? parentTarget;
  final Color _accountIconColor = const Color(0xFFA78BFA);

  IconData _mapIconNameToIconData(String name) {
    switch (name) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone_iphone':
        return Icons.phone_iphone;
      default:
        return Icons.money;
    }
  }

  // --- GETTER TOTAL SALDO (SEMUA WAKTU) ---
  int get totalSaldo => _balances.values.fold(0, (a, b) => a + b);

  // --- LOGIKA HITUNG STATISTIK BULANAN ---
  MonthlyStats _calculateMonthlyStats(bool isIncome) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Menghitung bulan lalu
    final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    int thisMonthTotal = 0;
    int lastMonthTotal = 0;

    for (var t in transactions) {
      // Filter tipe transaksi (Income/Expense)
      if (t.isIncome != isIncome) continue;

      try {
        // Parse tanggal dan amount dari model
        final tDate = DateTime.parse(t.date); // format yyyy-MM-dd
        final tAmount =
            int.tryParse(t.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        if (tDate.year == currentYear && tDate.month == currentMonth) {
          thisMonthTotal += tAmount;
        } else if (tDate.year == lastMonthYear && tDate.month == lastMonth) {
          lastMonthTotal += tAmount;
        }
      } catch (e) {
        debugPrint("Error parsing transaction for stats: $e");
      }
    }

    double percentage = 0.0;
    if (lastMonthTotal == 0) {
      // Jika bulan lalu 0, dan bulan ini ada, anggap naik 100%
      percentage = thisMonthTotal > 0 ? 100.0 : 0.0;
    } else {
      percentage = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
    }

    return MonthlyStats(
      currentMonthTotal: thisMonthTotal,
      percentageChange: percentage,
      isGrowthPositive: percentage >= 0,
    );
  }

  // Helper untuk format Rupiah
  String _formatCurrency(int value) {
    final s = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
    return s.replaceAll('Rp ', '').replaceAll(',', '.');
  }

  // GETTER UNTUK TARGET (Masih dipakai di card paling bawah)
  List<TargetModel> get childTargets => [];
  int get parentCurrent => _singleIncomeTarget?.currentAmount ?? 0;
  int get parentTargetAmount => _singleIncomeTarget?.targetAmount ?? 10000000;
  double get parentProgress =>
      parentTargetAmount == 0 ? 0 : parentCurrent / parentTargetAmount;

  Color get progressColor {
    if (parentProgress >= 1.0) return Colors.greenAccent;
    if (parentProgress >= 0.8) return Colors.greenAccent;
    if (parentProgress >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadAccounts();
    await _loadCategories();
    await _loadTransactions();
    await _loadTargets();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadAccounts() async {
    try {
      final accountsData = await supabase.from('accounts').select();
      final loadedAccounts = (accountsData as List).map((e) {
        final iconName = e['icon'] as String? ?? 'money';
        return AccountData(
          id: e['id'] as int,
          name: e['name'] as String,
          icon: _mapIconNameToIconData(iconName),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _accountList = loadedAccounts;
      });
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await supabase.from('categories').select();
      final loadedCategories = (categoriesData as List).map((e) {
        return CategoryData(
          id: e['id'] as int,
          name: e['name'] as String,
          type: e['type'] as String,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _categoryList = loadedCategories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadTransactions() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (_accountList.isEmpty) return;

    try {
      final transactionsData = await supabase
          .from('transactions')
          .select('*, category:category_id(name, type)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final Map<int, int> calculatedBalances = {
        for (var a in _accountList) a.id: 0
      };

      final List<TransactionModel> loadedTransactions = [];

      for (var t in (transactionsData as List)) {
        final type = t['type'] as String;
        final amount = (t['amount'] as num).toInt();
        final isIncome = type == 'income';
        final categoryMap = t['category'] as Map<String, dynamic>?;
        final categoryName = categoryMap?['name'] ?? 'Transfer';

        // Hitung Saldo Total (Akumulasi Semua Waktu)
        if (type == 'income') {
          final dstId = t['destination_account_id'] as int?;
          if (dstId != null)
            calculatedBalances[dstId] =
                (calculatedBalances[dstId] ?? 0) + amount;
        } else if (type == 'expense') {
          final srcId = t['source_account_id'] as int?;
          if (srcId != null)
            calculatedBalances[srcId] =
                (calculatedBalances[srcId] ?? 0) - amount;
        }

        loadedTransactions.add(TransactionModel(
          title: t['note'] ?? categoryName,
          category: categoryName,
          date:
              DateFormat('yyyy-MM-dd').format(DateTime.parse(t['created_at'])),
          amount: "Rp ${_formatCurrency(amount)}",
          isIncome: isIncome,
          icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          iconBgColor:
              isIncome ? const Color(0xFFEFFFF4) : const Color(0xFFFFF0F0),
          iconColor: isIncome ? Colors.green : Colors.red,
        ));
      }

      if (!mounted) return;
      setState(() {
        transactions = loadedTransactions;
        _balances = calculatedBalances;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  Future<void> _loadTargets() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('income_targets')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      // Hitung total income semua waktu untuk Target (bukan per bulan)
      int totalAllTimeIncome = 0;
      for (var t in transactions) {
        if (t.isIncome) {
          totalAllTimeIncome +=
              int.tryParse(t.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }

      TargetModel loadedTarget;
      if (data.isNotEmpty) {
        final t = data.first;
        final targetDateString = t['target_until'] as String?;
        final targetDate =
            targetDateString != null ? DateTime.parse(targetDateString) : null;

        loadedTarget = TargetModel(
          id: t['id'].toString(),
          title: t['title'] ?? 'Target Pemasukan',
          targetAmount: (t['target_amount'] as num).toInt(),
          currentAmount: totalAllTimeIncome, // Menggunakan total semua waktu
        );
        targetUntil = targetDate;
      } else {
        loadedTarget = TargetModel(
          id: 'default_parent',
          title: 'Target Pemasukan',
          targetAmount: 10000000,
          currentAmount: totalAllTimeIncome,
        );
        targetUntil = null;
      }

      if (!mounted) return;
      setState(() {
        _singleIncomeTarget = loadedTarget;
        parentTarget = loadedTarget;
        targets = [];
      });
    } catch (e) {
      debugPrint('Error loading target: $e');
    }
  }

  void _showTargetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit Target Pemasukan"),
            onTap: () {
              Navigator.pop(context);
              _editSingleTarget(context);
            },
          ),
        ],
      ),
    );
  }

  void _editSingleTarget(BuildContext context) {
    final target = _singleIncomeTarget;
    final nameCtrl =
        TextEditingController(text: target?.title ?? 'Target Pemasukan');
    final amountCtrl = TextEditingController(
        text: (target?.targetAmount ?? 10000000).toString());
    DateTime initialTargetDate = targetUntil ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Edit Target Pemasukan"),
        content: StatefulBuilder(builder: (context, innerSetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama Target"),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Nominal Target"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 5),
                    initialDate: initialTargetDate,
                  );
                  if (picked != null) {
                    innerSetState(() => initialTargetDate = picked);
                    setState(() => targetUntil = picked);
                  }
                },
                child: Text(
                  initialTargetDate.isBefore(DateTime(2001))
                      ? 'Pilih target sampai'
                      : 'Target sampai: ${DateFormat('dd MMM yyyy').format(initialTargetDate)}',
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final user = supabase.auth.currentUser;
              if (user == null) return;
              final int amount = int.tryParse(
                      amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final targetIdToUse = target?.id != 'default_parent'
                  ? int.tryParse(target!.id)
                  : null;

              final payload = {
                'user_id': user.id,
                if (targetIdToUse != null) 'id': targetIdToUse,
                'title': nameCtrl.text,
                'target_amount': amount,
                'target_until': (targetUntil ?? DateTime.now())
                    .toIso8601String()
                    .substring(0, 10),
              };

              try {
                await supabase
                    .from('income_targets')
                    .upsert(payload, onConflict: 'user_id');
              } catch (e) {
                debugPrint('Error saving target: $e');
              }
              if (!mounted) return;
              Navigator.pop(dialogContext);
              _loadTargets();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Statistik Pemasukan Bulan Ini
    final incomeStats = _calculateMonthlyStats(true);
    // 2. Hitung Statistik Pengeluaran Bulan Ini
    final expenseStats = _calculateMonthlyStats(false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // --- HALAMAN HOME (REKAP) ---
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Halo! 👋',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Selamat datang kembali!',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // --- KARTU TOTAL SALDO UTAMA ---
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
                                child: Text('Total Saldo',
                                    style: TextStyle(color: Colors.white70))),
                            IconButton(
                              icon: Icon(
                                  _showBalance
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white),
                              onPressed: () =>
                                  setState(() => _showBalance = !_showBalance),
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
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- AREA CHART ---
                  WeeklyChart(transactions: transactions),
                  const SizedBox(height: 20),

                  // --- ROW KARTU PEMASUKAN & PENGELUARAN (REVISI) ---
                  Row(
                    children: [
                      // KARTU PEMASUKAN
                      _buildSummaryCard(
                        title: 'Pemasukan',
                        amount:
                            incomeStats.currentMonthTotal, // Total Bulan Ini
                        percent:
                            incomeStats.percentageChange, // % vs Bulan Lalu
                        isIncome: true, // Untuk warna Hijau/Merah logika Income
                      ),
                      const SizedBox(width: 12),
                      // KARTU PENGELUARAN
                      _buildSummaryCard(
                        title: 'Pengeluaran',
                        amount:
                            expenseStats.currentMonthTotal, // Total Bulan Ini
                        percent:
                            expenseStats.percentageChange, // % vs Bulan Lalu
                        isIncome:
                            false, // Untuk warna Hijau/Merah logika Expense
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // --- GRID AKUN ---
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35),
                    itemCount: _accountList.length,
                    itemBuilder: (context, i) {
                      final account = _accountList[i];
                      final bal = _balances[account.id] ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  _accountIconColor.withOpacity(0.12),
                              child:
                                  Icon(account.icon, color: _accountIconColor),
                            ),
                            const SizedBox(height: 8),
                            Text(account.name,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("Rp ${_formatCurrency(bal)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- TARGET PEMASUKAN (Tetap di Bawah) ---
                  GestureDetector(
                    onTap: () => _showTargetOptions(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA78BFA), Color(0xFFB79CFF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Target Pemasukan",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            "Rp ${_formatCurrency(parentCurrent)} / Rp ${_formatCurrency(parentTargetAmount)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: parentProgress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                          if (targetUntil != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "Target sampai: ${DateFormat('dd MMM yyyy').format(targetUntil!)}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

          // SCREEN LAINNYA
          CatatanScreen(categoryList: _categoryList),
          KalenderScreen(transactions: transactions),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (_currentIndex == 2 || _currentIndex == 3)
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFA78BFA),
                child: const Icon(Icons.add, size: 28, color: Colors.white),
                onPressed: () async {
                  final user = supabase.auth.currentUser;
                  if (user == null) return;
                  if (_accountList.isEmpty || _categoryList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data belum dimuat.')));
                    return;
                  }

                  final result = await showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Popup',
                    barrierColor: Colors.black.withOpacity(0.4),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => const SizedBox(),
                    transitionBuilder: (context, animation, _, __) {
                      return SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 1), end: Offset.zero)
                            .animate(animation),
                        child: AddTransactionPopup(
                          sources: _accountList.map((a) => a.name).toList(),
                          sourceIcons: _accountList.map((a) => a.icon).toList(),
                          expenseCategories: _categoryList
                              .where((c) => c.type == 'expense')
                              .map((c) => c.name)
                              .toList(),
                          incomeCategories: _categoryList
                              .where((c) => c.type == 'income')
                              .map((c) => c.name)
                              .toList(),
                        ),
                      );
                    },
                  );

                  if (result is Map) {
                    final int tab = result['tab'] ?? 0;
                    final int amount = result['amount'] ?? 0;
                    final srcIndex = result['sourceIndex'] ?? -1;
                    final dstIndex = result['destinationIndex'] ?? -1;
                    final catIndex = result['categoryIndex'] ?? -1;
                    final note = result['note'] ?? '';
                    final date = DateTime.parse(result['date']);

                    final srcId =
                        srcIndex >= 0 ? _accountList[srcIndex].id : null;
                    final dstId =
                        dstIndex >= 0 ? _accountList[dstIndex].id : null;

                    List<CategoryData> activeCats = _categoryList
                        .where(
                            (c) => c.type == (tab == 0 ? 'expense' : 'income'))
                        .toList();
                    final catId =
                        (catIndex >= 0 && catIndex < activeCats.length)
                            ? activeCats[catIndex].id
                            : null;

                    if (amount > 0 && catId != null) {
                      try {
                        await supabase.from('transactions').insert({
                          'user_id': user.id,
                          'type': tab == 0 ? 'expense' : 'income',
                          'amount': amount,
                          'category_id': catId,
                          'source_account_id': tab == 0 ? srcId : null,
                          'destination_account_id': tab == 1 ? dstId : null,
                          'note': note.isNotEmpty ? note : null,
                          'created_at': date.toIso8601String(),
                        });
                        await _loadAllData(); // Reload data
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    }
                  }
                },
              ),
            ),
    );
  }

  // --- WIDGET KARTU BARU (PEMASUKAN / PENGELUARAN) ---
  Widget _buildSummaryCard({
    required String title,
    required int amount,
    required double percent,
    required bool isIncome,
  }) {
    // Logika Warna Indikator
    // Untuk Pemasukan: Naik (+) = Hijau, Turun (-) = Merah
    // Untuk Pengeluaran: Naik (+) = Merah (Boros), Turun (-) = Hijau (Hemat)

    final bool isPositive = percent >= 0;

    Color growthColor;
    if (isIncome) {
      growthColor = isPositive ? Colors.green : Colors.red;
    } else {
      growthColor = isPositive ? Colors.red : Colors.green;
    }

    final String sign = isPositive ? '+' : '';
    final String percentText =
        "$sign${percent.toStringAsFixed(1)}% dari bulan lalu";

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
                      isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    isIncome ? Icons.trending_up : Icons.trending_down,
                    // Icon Pemasukan selalu 'Trending Up' style, Pengeluaran 'Trending Down' style (opsional)
                    // Atau bisa dinamis berdasarkan 'isPositive'.
                    // Di sini saya ikuti style umum: Pemasukan (Hijau), Pengeluaran (Merah)
                    color: isIncome ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Rp ${_formatCurrency(amount)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              percentText,
              style: TextStyle(
                color: growthColor,
                fontSize: 11, // Sedikit lebih kecil agar muat
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
