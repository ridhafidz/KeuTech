import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:keutech/models/transaction_model.dart';

class KalenderScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  const KalenderScreen({super.key, required this.transactions});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  final Color themeColor = const Color(0xFFA694F6);
  final ScrollController _transactionScroll = ScrollController();

  late DateTime selectedDate;
  late DateTime currentMonth;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    currentMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  void _scrollToTop() {
    if (_transactionScroll.hasClients) {
      _transactionScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _transactionScroll.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year,
        currentMonth.month + offset,
      );

      selectedDate = DateTime(
        currentMonth.year,
        currentMonth.month,
        selectedDate.day,
      );
    });
  }

  List<TransactionModel> get dailyTransactions {
    final selected = DateFormat('yyyy-MM-dd').format(selectedDate);
    return widget.transactions.where((t) => t.date == selected).toList();
  }

  List<TransactionModel> get monthlyTransactions {
    return widget.transactions.where((t) {
      final date = DateTime.parse(t.date);
      return date.year == currentMonth.year && date.month == currentMonth.month;
    }).toList();
  }

  List<DateTime> get daysInMonth {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final totalDays =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    return List.generate(
      totalDays,
      (i) => DateTime(currentMonth.year, currentMonth.month, i + 1),
    );
  }

  int get firstWeekday {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    return firstDay.weekday % 7;
  }

  bool _hasIncome(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return widget.transactions.any(
      (t) => t.date == key && t.isIncome,
    );
  }

  bool _hasExpense(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return widget.transactions.any((t) => t.date == key && !t.isIncome);
  }

  int _parseAmount(String amount) {
    return int.tryParse(amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _exportMonthlyReport() async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final monthStr = DateFormat('MMMM yyyy', 'id').format(currentMonth);
      final data = monthlyTransactions;

      // Sort tanggal
      data.sort((a, b) => a.date.compareTo(b.date));

      int totalIn = 0;
      int totalOut = 0;

      for (var t in data) {
        int val = _parseAmount(t.amount);
        if (t.isIncome)
          totalIn += val;
        else
          totalOut += val;
      }
      int balance = totalIn - totalOut;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Laporan Keuangan',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(monthStr, style: const pw.TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Ringkasan
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStat('Pemasukan', totalIn, PdfColors.green),
                    _buildPdfStat('Pengeluaran', totalOut, PdfColors.red),
                    _buildPdfStat('Sisa Saldo', balance, PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabel
              pw.Table.fromTextArray(
                headers: ['Tanggal', 'Kategori', 'Catatan', 'Nominal'],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.purple),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: data.map((t) {
                  return [
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(t.date)),
                    t.category,
                    t.title,
                    (t.isIncome ? '+ ' : '- ') + t.amount,
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_$monthStr',
      );
    } catch (e) {
      debugPrint("Error export PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Gagal membuat PDF")));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildPdfStat(String label, int value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
              .format(value),
          style: pw.TextStyle(
              fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _calendarHeader(),
            const SizedBox(height: 16),
            _calendarGrid(),
            const SizedBox(height: 24),
            _transactionHeader(),
            const SizedBox(height: 12),
            Expanded(child: _transactionList()),
          ],
        ),
      ),
    );
  }

  Widget _calendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Kalender",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        // Bagian Navigasi Bulan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.grey.shade200), // Sedikit border biar rapi
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => _changeMonth(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMM yyyy', 'id').format(currentMonth),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => _changeMonth(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendarGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _dayHeader(),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              ...List.generate(
                firstWeekday,
                (_) => const SizedBox(),
              ),
              ...daysInMonth.map(_dateItem),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayHeader() {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: days
          .map(
            (d) => Center(
              child: Text(d, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
    );
  }

  Widget _dateItem(DateTime date) {
    final isSelected = DateUtils.isSameDay(date, selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final hasIncome = _hasIncome(date);
    final hasExpense = _hasExpense(date);

    return GestureDetector(
      onTap: () {
        setState(() => selectedDate = date);
        _scrollToTop();
      },
      child: SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                "${date.day}",
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? themeColor
                          : Colors.black,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (hasIncome || hasExpense)
              Positioned(
                bottom: 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: 1,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 250),
                    scale: isSelected ? 1.2 : 1,
                    child: Row(
                      children: [
                        if (hasIncome)
                          _dot(
                            color: Colors.green,
                          ),
                        if (hasIncome && hasExpense) const SizedBox(width: 3),
                        if (hasExpense)
                          _dot(
                            color: Colors.red,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot({required Color color}) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _transactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Transaksi - ${DateFormat('d MMM', 'id').format(selectedDate)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (_isExporting)
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(color: themeColor, strokeWidth: 2),
          )
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _exportMonthlyReport,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, size: 16, color: themeColor),
                    const SizedBox(width: 6),
                    Text(
                      "Cetak Laporan",
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _transactionList() {
    if (dailyTransactions.isEmpty) {
      return const Center(child: Text("Tidak ada transaksi"));
    }

    return ListView.separated(
      controller: _transactionScroll,
      itemCount: dailyTransactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final t = dailyTransactions[i];
        final Color bgColor =
            t.isIncome ? Colors.green.shade50 : Colors.red.shade50;
        final Color iconColor = t.isIncome ? Colors.green : Colors.red;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: bgColor,
                child: Icon(t.icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(t.category,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600))
                  ],
                ),
              ),
              Text(
                (t.isIncome ? "+ " : "- ") + t.amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: t.isIncome ? Colors.green : Colors.red,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  int get totalIncome {
    return dailyTransactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + _parseAmount(t.amount));
  }

  int get totalExpense {
    return dailyTransactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + _parseAmount(t.amount));
  }
}
