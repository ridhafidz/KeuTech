import 'package:flutter/material.dart';

class TransactionModel {
  final String title;
  final String category;
  final String date;
  final String amount;
  final bool isIncome;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  TransactionModel({
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}
