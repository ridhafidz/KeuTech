import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class WeeklyChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const WeeklyChart({super.key, required this.transactions});

  // Helper untuk mendapatkan data Minggu Ini (Senin s/d Minggu)
  List<Map<String, dynamic>> get _weeklyData {
    final now = DateTime.now();

    // 1. Cari tanggal hari Senin pada minggu ini
    // now.weekday: 1=Senin, ..., 7=Minggu
    // Jika hari ini Rabu (3), kita kurangi 2 hari untuk dapat Senin.
    final monday = now.subtract(Duration(days: now.weekday - 1));

    // 2. Generate 7 hari dimulai dari Senin tersebut
    return List.generate(7, (index) {
      // index 0 = Senin, index 1 = Selasa, dst...
      final date = monday.add(Duration(days: index));

      int income = 0;
      int expense = 0;

      for (var t in transactions) {
        try {
          final tDate = DateTime.parse(t.date);
          // Cek tanggal sama
          if (tDate.year == date.year &&
              tDate.month == date.month &&
              tDate.day == date.day) {
            final amount =
                int.tryParse(t.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (t.isIncome) {
              income += amount;
            } else {
              expense += amount;
            }
          }
        } catch (e) {
          // ignore
        }
      }

      return {
        'day': DateFormat.E('id_ID').format(date), // Sen, Sel, Rab...
        'income': income,
        'expense': expense,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _weeklyData;

    // Cari nilai maksimum global untuk skala Y
    double maxVal = 0;
    for (var d in data) {
      if ((d['income'] as int) > maxVal)
        maxVal = (d['income'] as int).toDouble();
      if ((d['expense'] as int) > maxVal)
        maxVal = (d['expense'] as int).toDouble();
    }
    if (maxVal == 0) maxVal = 100000;
    maxVal = maxVal * 1.2; // Buffer atas

    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arus Keuangan Mingguan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  // Ubah teks ini agar sesuai konteks
                  Text(
                    'Minggu Ini',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              // Legenda
              Row(
                children: [
                  _buildLegendIndicator(const Color(0xFF22C55E), 'Masuk'),
                  const SizedBox(width: 10),
                  _buildLegendIndicator(const Color(0xFFEF4444), 'Keluar'),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[groupIndex];
                      final amount =
                          rodIndex == 0 ? item['income'] : item['expense'];
                      final label = rodIndex == 0 ? 'Masuk' : 'Keluar';
                      return BarTooltipItem(
                        '$label\n${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount)}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[index]
                                  ['day'], // Akan selalu Sen, Sel, Rab...
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final income = (item['income'] as int).toDouble();
                  final expense = (item['expense'] as int).toDouble();

                  // Bar minimum height (agar tetap terlihat titiknya jika 0)
                  final double incomeHeight =
                      income > 0 ? income : maxVal * 0.015;
                  final double expenseHeight =
                      expense > 0 ? expense : maxVal * 0.015;

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      // Batang Pemasukan (Hijau)
                      BarChartRodData(
                        toY: incomeHeight,
                        color: const Color(0xFF22C55E),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal,
                          color: Colors.grey.shade50,
                        ),
                      ),
                      // Batang Pengeluaran (Merah)
                      BarChartRodData(
                        toY: expenseHeight,
                        color: const Color(0xFFEF4444),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal,
                          color: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
