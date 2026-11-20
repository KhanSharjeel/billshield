import 'package:flutter/material.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/services/hive_storage_service.dart';
import 'package:billshield/screens/bill_breakdown_screen.dart';

class SavedBillsScreen extends StatefulWidget {
  const SavedBillsScreen({super.key});

  @override
  State<SavedBillsScreen> createState() => _SavedBillsScreenState();
}

class _SavedBillsScreenState extends State<SavedBillsScreen> {
  List<BillCalculation> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    setState(() {
      _bills = HiveStorageService.getSavedBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Simulations')),
      body: _bills.isEmpty
          ? const Center(child: Text('No saved bill simulations yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return Card(
            child: ListTile(
              title: Text(
                '${bill.provider} • Rs. ${bill.totalBill.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${bill.totalUnits.toStringAsFixed(1)} kWh • '
                    '${bill.isProtected ? "Protected" : "Unprotected"}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await HiveStorageService.deleteBillAt(index);
                  _loadBills();
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillBreakdownScreen(calculation: bill),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}