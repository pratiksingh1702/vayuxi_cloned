import 'package:flutter/material.dart';

class LossScreen extends StatelessWidget {
  final String siteName;
  final dynamic income;
  final dynamic expenses;
  final dynamic loss;
  final double profitPercentage;
  final String month;
  final String year;

  const LossScreen({
    super.key,
    required this.siteName,
    required this.income,
    required this.expenses,
    required this.loss,
    required this.profitPercentage,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCFE8FA),
      appBar: AppBar(
        title: Text("Loss - $siteName"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$month / $year", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            _infoTile("Income (₹)", income.toString()),
            _infoTile("Expenses (₹)", expenses.toString()),
            _infoTile("Loss (₹)", loss.toString()),
            _infoTile("Loss (%)", profitPercentage.abs().toStringAsFixed(2)),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}
