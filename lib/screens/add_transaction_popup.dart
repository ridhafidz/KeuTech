import 'package:flutter/material.dart';

class AddTransactionPopup extends StatefulWidget {
  const AddTransactionPopup({super.key});

  @override
  State<AddTransactionPopup> createState() => _AddTransactionPopupState();
}

class _AddTransactionPopupState extends State<AddTransactionPopup>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  int selectedCategoryIndex = -1;
  int selectedSourceIndex = -1;
  int selectedDestinationIndex = -1;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double _dragOffset = 0.0;
  late final AnimationController _resetController;
  Animation<double>? _resetAnimation;

  final sources = ['Cash', 'Tabungan', 'Bank', 'Dompet Digital'];
  final destinations = ['Cash', 'Bank', 'Dompet Digital', 'Tabungan'];

  final sourceIcons = [
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.account_balance,
    Icons.phone_iphone,
  ];

  final expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
  ];

  final incomeCategories = ['Gaji', 'Bonus', 'Bisnis', 'Investasi'];

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                          _tabItem('Transfer', 2),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              if (selectedTab != 1) ...[
                                const Text('Sumber'),
                                const SizedBox(height: 12),

                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(sources.length, (i) {
                                    final isSelected =
                                        selectedSourceIndex == i;

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
                                const Text('Tujuan'),
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
                                decoration:
                                    _inputDecoration('Tambah catatan (opsional)'),
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
                          ),
                          onPressed: _onSavePressed,
                          child: const Text(
                            'Simpan',
                            style: TextStyle(color: Colors.white),
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
    final text =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }

    final result = {
      'tab': selectedTab,
      'amount': amount,
      'categoryIndex': selectedCategoryIndex,
      'sourceIndex': selectedSourceIndex,
      'destinationIndex': selectedDestinationIndex,
      'note': _noteController.text,
    };

    Navigator.pop(context, result);
  }

  List<String> get _activeCategories {
    if (selectedTab == 1) return incomeCategories;
    return expenseCategories;
  }

  Widget _tabItem(String title, int index) {
    final isActive = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
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
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF6B4EFF) : Colors.grey,
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

  const SourceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEDE7FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
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
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF6B4EFF) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
