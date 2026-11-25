import 'package:flutter/material.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/database/app_database.dart';
import 'package:billshield/services/hive_storage_service.dart';
import 'package:billshield/screens/bill_breakdown_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BillCalculation> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final dbBills = await AppDatabase.instance.getSavedBills();
      if (dbBills.isNotEmpty) {
        setState(() {
          _bills = dbBills;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback to Hive if DB empty
    final hiveBills = HiveStorageService.getSavedBills();
    setState(() {
      _bills = hiveBills;
      _isLoading = false;
    });
  }

  Future<void> _deleteBillWithUndo(BillCalculation bill, int index) async {
    final deletedBill = bill;
    if (bill.id != null) {
      await AppDatabase.instance.deleteBill(bill.id!);
    }
    await HiveStorageService.deleteBillAt(index);
    await _loadBills();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted simulation for ${deletedBill.provider}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await AppDatabase.instance.insertBill(deletedBill);
            await HiveStorageService.saveBill(deletedBill);
            _loadBills();
          },
        ),
      ),
    );
  }

  Future<void> _clearAllWithUndo() async {
    if (_bills.isEmpty) return;
    final previousBills = List<BillCalculation>.from(_bills);
    await AppDatabase.instance.clearAllBills();
    await HiveStorageService.clearAllBills();
    await _loadBills();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared all saved bill history'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            for (final b in previousBills) {
              await AppDatabase.instance.insertBill(b);
              await HiveStorageService.saveBill(b);
            }
            _loadBills();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Bill Simulations'),
        actions: [
          if (_bills.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text(
                      'Are you sure you want to delete all saved bill simulations?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearAllWithUndo();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bills.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Saved Simulations Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Saved bill calculations will appear here.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _bills.length,
                      itemBuilder: (context, index) {
                        final bill = _bills[index];
                        final dateStr =
                            '${bill.timestamp.day}/${bill.timestamp.month}/${bill.timestamp.year} ${bill.timestamp.hour}:${bill.timestamp.minute.toString().padLeft(2, '0')}';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: bill.isProtected
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              child: Icon(
                                bill.isProtected
                                    ? Icons.shield_outlined
                                    : Icons.warning_amber_outlined,
                                color: bill.isProtected
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                            title: Text(
                              '${bill.provider} • Rs. ${bill.totalBill.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${bill.totalUnits.toStringAsFixed(1)} kWh • ${bill.isProtected ? "Protected" : "Unprotected"}${bill.isThreePhase ? " • 3-Phase" : ""}\n$dateStr',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteBillWithUndo(bill, index),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BillBreakdownScreen(calculation: bill),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
