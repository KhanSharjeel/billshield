import 'package:material_ui/material_ui.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/services/hive_storage_service.dart';

class BillBreakdownScreen extends StatelessWidget {
  final BillCalculation calculation;

  const BillBreakdownScreen({super.key, required this.calculation});

  Widget _row(String label, double amount, {bool isBold = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 17 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itemized Bill Breakdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCO: ${calculation.provider}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Units: ${calculation.totalUnits.toStringAsFixed(1)} kWh '
                          '(Off-Peak: ${calculation.offPeakUnits.toStringAsFixed(1)}, '
                          'Peak: ${calculation.peakUnits.toStringAsFixed(1)})',
                    ),
                    const Divider(height: 24),
                    _row('Base Energy Charge', calculation.baseEnergyCharge),
                    _row('Fuel Price Adjustment (FPA)', calculation.fpaCharge),
                    _row('Quarterly Tariff Adj. (QTA)', calculation.qtaCharge),
                    _row('GST & Electricity Duties', calculation.gstAndDuties),
                    const Divider(height: 24),
                    _row('Estimated Total Bill', calculation.totalBill,
                        isBold: true),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Save Simulation to History'),
              onPressed: () async {
                await HiveStorageService.saveBill(calculation);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulation saved to Hive.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}