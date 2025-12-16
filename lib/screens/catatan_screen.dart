import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keutech/models/transaction_model.dart';
import 'package:keutech/screens/home_screen.dart';

class CatatanScreen extends StatefulWidget {
  final List<CategoryData> categoryList;

  const CatatanScreen({
    super.key,
    required this.categoryList,
  });

  @override
  State<CatatanScreen> createState() => _CatatanScreenState();
}

class _CatatanScreenState extends State<CatatanScreen> {
  final supabase = Supabase.instance.client;

  // State Data
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  // Filter State
  int selectedFilterTab = 0;
  String searchQuery = '';
  String? selectedTransactionType;
  String? selectedCategoryName;
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;

  bool get isFilterActive {
    return selectedTransactionType != null ||
        selectedCategoryName != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null;
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      dynamic query = supabase
          .from('transactions')
          .select('*, category:category_id(name, type)');

      query = query.eq('user_id', user.id);

      if (selectedFilterTab == 1) {
        query = query.eq('type', 'income');
      } else if (selectedFilterTab == 2) {
        query = query.eq('type', 'expense');
      }

      if (selectedTransactionType != null) {
        query = query.eq('type', selectedTransactionType!);
      }

      if (selectedCategoryName != null) {
        final catData = widget.categoryList.firstWhere(
          (c) => c.name == selectedCategoryName,
          orElse: () => CategoryData(id: -1, name: '', type: ''),
        );
        if (catData.id != -1) {
          query = query.eq('category_id', catData.id);
        }
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate!.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay =
            DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }

      if (minAmount != null) {
        query = query.gte('amount', minAmount!);
      }
      if (maxAmount != null) {
        query = query.lte('amount', maxAmount!);
      }

      if (searchQuery.isNotEmpty) {
        query = query.ilike('note', '%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      final List<TransactionModel> loaded = (response as List).map((t) {
        final type = t['type'] as String;
        final amount = (t['amount'] as num).toInt();
        final isIncome = type == 'income';

        final categoryMap = t['category'] as Map<String, dynamic>?;
        final categoryName = categoryMap?['name'] ?? 'Umum';

        return TransactionModel(
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
        );
      }).toList();

      if (mounted) {
        setState(() {
          _transactions = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper Format Currency
  String _formatCurrency(int value) {
    final s = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
    return s.replaceAll('Rp ', '').replaceAll(',', '.');
  }

  void _openFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Logika Dinamis untuk Dropdown Kategori
            List<String> dynamicCategories = [];
            if (selectedTransactionType != null) {
              dynamicCategories = widget.categoryList
                  .where((e) => e.type == selectedTransactionType)
                  .map((e) => e.name)
                  .toSet()
                  .toList();
              dynamicCategories.sort();
            }

            Future<void> pickDate(bool isStart) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isStart
                    ? (startDate ?? DateTime.now())
                    : (endDate ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                locale: const Locale('id', 'ID'),
              );

              if (picked != null) {
                setModalState(() {
                  if (isStart)
                    startDate = picked;
                  else
                    endDate = picked;
                });
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                top: 12,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar UI ...
                        Center(
                            child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10)))),
                        const Text("Filter Transaksi",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Input Tanggal
                        const Text("Tanggal"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _dateBox(
                                    label: "Dari",
                                    date: startDate,
                                    onTap: () => pickDate(true))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _dateBox(
                                    label: "Sampai",
                                    date: endDate,
                                    onTap: () => pickDate(false))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Input Jenis Transaksi
                        const Text("Jenis Transaksi"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _choiceChip("Pemasukan", "income", setModalState),
                            _choiceChip(
                                "Pengeluaran", "expense", setModalState),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Input Kategori (Dinamis)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: selectedTransactionType == null
                              ? const SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Kategori"),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: dynamicCategories
                                              .contains(selectedCategoryName)
                                          ? selectedCategoryName
                                          : null,
                                      hint: const Text("Pilih kategori"),
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                      items: dynamicCategories
                                          .map((c) => DropdownMenuItem(
                                              value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (v) => setModalState(
                                          () => selectedCategoryName = v),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                        ),

                        // Input Nominal
                        const Text("Nominal"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        hintText: "Min (Rp)"),
                                    onChanged: (v) =>
                                        minAmount = double.tryParse(v))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        hintText: "Max (Rp)"),
                                    onChanged: (v) =>
                                        maxAmount = double.tryParse(v))),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Tombol Aksi
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // RESET FILTER
                                  setState(() {
                                    selectedTransactionType = null;
                                    selectedCategoryName = null;
                                    startDate = null;
                                    endDate = null;
                                    minAmount = null;
                                    maxAmount = null;
                                  });
                                  Navigator.pop(context);
                                  _fetchTransactions(); // Refresh data tanpa filter
                                },
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: const Text("Reset"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // APPLY FILTER
                                  Navigator.pop(context);
                                  _fetchTransactions(); // Panggil Fetch Data Baru!
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB79CFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: const Text("Terapkan"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _choiceChip(String label, String value,
      void Function(void Function()) setModalState) {
    final isSelected = selectedTransactionType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFEDE7FF),
      labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFB79CFF) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
          color: isSelected ? const Color(0xFFB79CFF) : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        setModalState(() {
          selectedTransactionType = selected ? value : null;
          selectedCategoryName = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Catatan',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // SEARCH BAR
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      // Panggil fetch saat user selesai mengetik atau tekan enter
                      // Untuk performa, bisa pakai onSubmitted atau debounce
                      onSubmitted: (v) {
                        setState(() => searchQuery = v);
                        _fetchTransactions();
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari catatan & enter...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // FILTER BUTTON
                SizedBox(
                  height: 50,
                  width: 50,
                  child: InkWell(
                    onTap: _openFilterMenu,
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Icon(Icons.filter_list)),
                        ),
                        if (isFilterActive)
                          Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFB79CFF),
                                      shape: BoxShape.circle))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterTab("Semua", 0),
                  _filterTab("Pemasukan", 1),
                  _filterTab("Pengeluaran", 2),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LIST TRANSAKSI
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? const Center(child: Text("Tidak ada data ditemukan"))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) =>
                              TransactionItem(data: _transactions[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String text, int index) {
    final isSelected = selectedFilterTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilterTab = index);
        _fetchTransactions(); // Fetch ulang saat tab ganti
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB79CFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF535D6E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Widget ITEM dan DATE BOX sama seperti sebelumnya
class TransactionItem extends StatelessWidget {
  final TransactionModel data;
  const TransactionItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
                color: data.iconBgColor,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(data.icon, color: data.iconColor ?? Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data.category, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(data.date,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Text(
            (data.isIncome ? "+ " : "- ") + data.amount,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: data.isIncome ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
}

Widget _dateBox(
    {required String label,
    required DateTime? date,
    required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: Center(
        child: Text(
          date == null ? label : "${date.day}/${date.month}/${date.year}",
          style: TextStyle(
              color: date == null ? Colors.grey : Colors.black,
              fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
}
