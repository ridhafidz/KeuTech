import 'package:flutter/material.dart';

class AddTransactionPopup extends StatefulWidget {
  final List<String> sources;
  final List<IconData> sourceIcons;
  final List<String> expenseCategories;
  final List<String> incomeCategories;

  const AddTransactionPopup({
    super.key,
    required this.sources,
    required this.sourceIcons,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  @override
  State<AddTransactionPopup> createState() => _AddTransactionPopupState();
}

class _AddTransactionPopupState extends State<AddTransactionPopup>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  int selectedCategoryIndex = -1;
  int selectedSourceIndex = -1;
  DateTime _selectedDate = DateTime.now();
  int selectedDestinationIndex = -1;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double _dragOffset = 0.0;
  late final AnimationController _resetController;
  Animation<double>? _resetAnimation;

  List<String> get sources => widget.sources;
  List<IconData> get sourceIcons => widget.sourceIcons;
  List<String> get destinations => widget.sources;
  List<String> get expenseCategories => widget.expenseCategories;
  List<String> get incomeCategories => widget.incomeCategories;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dy).clamp(
                  0.0,
                  MediaQuery.of(context).size.height,
                );
              });
            }
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (_dragOffset > 150 || velocity > 800) {
              Navigator.pop(context);
              return;
            }

            _resetAnimation = Tween(begin: _dragOffset, end: 0.0).animate(
              CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
            )..addListener(() {
                setState(() {
                  _dragOffset = _resetAnimation!.value;
                });
              });

            _resetController
              ..reset()
              ..forward();
          },
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              child: SafeArea(
                top: false,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.92,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tambah Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _tabItem('Pengeluaran', 0),
                          _tabItem('Pemasukan', 1),
                          // Tab Transfer dihapus
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(Icons.calendar_today,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Jumlah'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Masukkan jumlah'),
                              ),
                              const SizedBox(height: 20),
                              const Text('Kategori'),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _activeCategories.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.8,
                                ),
                                itemBuilder: (context, index) {
                                  final isSelected =
                                      selectedCategoryIndex == index;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategoryIndex = index;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEDE7FF)
                                            : const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _activeCategories[index],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? const Color(0xFFB79CFF)
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              if (selectedTab == 0) ...[
                                const Text('Sumber (Pengeluaran)'),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(sources.length, (i) {
                                    final isSelected = selectedSourceIndex == i;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedSourceIndex = i;
                                        });
                                      },
                                      child: SourceCard(
                                        title: sources[i],
                                        icon: sourceIcons[i],
                                        isSelected: isSelected,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (selectedTab == 1) ...[
                                const Text('Tujuan (Pemasukan)'),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(destinations.length, (
                                    i,
                                  ) {
                                    final isSelected =
                                        selectedDestinationIndex == i;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedDestinationIndex = i;
                                        });
                                      },
                                      child: SourceCard(
                                        title: destinations[i],
                                        icon: sourceIcons[i],
                                        isSelected: isSelected,
                                        isError:
                                            false, // Error state dihilangkan
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                              ],
                              const Text('Catatan'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                    'Tambah catatan (opsional)'),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB79CFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _onSavePressed,
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }

    if (selectedCategoryIndex == -1) {
      // Kategori wajib dipilih
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori')),
      );
      return;
    }

    // Pengecekan Akun Sumber/Tujuan
    if (selectedTab == 0 && selectedSourceIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sumber akun (Pengeluaran)')),
      );
      return;
    }

    if (selectedTab == 1 && selectedDestinationIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tujuan akun (Pemasukan)')),
      );
      return;
    }

    // Mengirim Index kembali, HomeScreen yang akan mengkonversi Index ke ID DB
    final result = {
      'tab': selectedTab,
      'amount': amount,
      'categoryIndex': selectedCategoryIndex,
      'sourceIndex': selectedSourceIndex,
      'destinationIndex': selectedDestinationIndex,
      'note': _noteController.text,
      'date': _selectedDate.toIso8601String(),
    };

    debugPrint(
        '--- [POPUP RESULT] Data Dikirim ke HomeScreen (No Transfer) ---');
    debugPrint(result.toString());
    debugPrint(
        '---------------------------------------------------------------');

    Navigator.pop(context, result);
  }

  List<String> get _activeCategories {
    if (selectedTab == 0) return expenseCategories;
    // Karena hanya ada dua tab, jika bukan 0, pasti 1 (Pemasukan)
    return incomeCategories;
  }

  Widget _tabItem(String title, int index) {
    final isActive = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
            // Reset pilihan saat berganti tab
            selectedCategoryIndex = -1;
            selectedSourceIndex = -1;
            selectedDestinationIndex = -1;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEDE7FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isActive ? const Color(0xFFB79CFF) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFFB79CFF) : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class SourceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isError;

  const SourceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Logika isError dihilangkan karena tidak ada Transfer
    Color borderColor =
        isSelected ? const Color(0xFFB79CFF) : Colors.grey.shade300;
    Color backgroundColor = isSelected ? const Color(0xFFEDE7FF) : Colors.white;
    Color contentColor = isSelected ? const Color(0xFFB79CFF) : Colors.black87;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: contentColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
