import 'package:flutter/services.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, double pct) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label (${pct.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _buildSummaryText() {
    final status =
    calculation.isProtected ? 'Protected (<=200 kWh)' : 'Unprotected (>200 kWh)';
    final buffer = StringBuffer()
      ..writeln('BillShield — ${calculation.provider} Estimate')
      ..writeln('Status: $status')
      ..writeln(
        'Units: ${calculation.totalUnits.toStringAsFixed(1)} kWh '
            '(Off-Peak: ${calculation.offPeakUnits.toStringAsFixed(1)}, '
            'Peak: ${calculation.peakUnits.toStringAsFixed(1)})',
      )
      ..writeln('Base Energy: Rs. ${calculation.baseEnergyCharge.toStringAsFixed(2)}')
      ..writeln('FPA: Rs. ${calculation.fpaCharge.toStringAsFixed(2)}')
      ..writeln('QTA: Rs. ${calculation.qtaCharge.toStringAsFixed(2)}');

    if (calculation.fixedCharges > 0) {
      buffer.writeln('Fixed Charges: Rs. ${calculation.fixedCharges.toStringAsFixed(2)}');
    }
    if (calculation.meterRent > 0) {
      buffer.writeln('Meter Rent: Rs. ${calculation.meterRent.toStringAsFixed(2)}');
    }

    buffer
      ..writeln('GST & Duties: Rs. ${calculation.gstAndDuties.toStringAsFixed(2)}')
      ..writeln('Total Payable: Rs. ${calculation.totalBill.toStringAsFixed(2)}');

    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final total = calculation.totalBill > 0 ? calculation.totalBill : 1.0;
    final otherCharges = calculation.fpaCharge +
        calculation.qtaCharge +
        calculation.fixedCharges +
        calculation.meterRent;

    final energyFlex =
    ((calculation.baseEnergyCharge / total) * 1000).round().clamp(0, 1000);
    final otherFlex =
    ((otherCharges / total) * 1000).round().clamp(0, 1000);
    final taxFlex =
    ((calculation.gstAndDuties / total) * 1000).round().clamp(0, 1000);

    final energyPct =
    calculation.totalBill > 0 ? (calculation.baseEnergyCharge / total) * 100 : 0.0;
    final otherPct =
    calculation.totalBill > 0 ? (otherCharges / total) * 100 : 0.0;
    final taxPct =
    calculation.totalBill > 0 ? (calculation.gstAndDuties / total) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Itemized Bill Breakdown')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cost Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          if (energyFlex > 0)
                            Expanded(
                              flex: energyFlex,
                              child: Container(color: Colors.blue),
                            ),
                          if (otherFlex > 0)
                            Expanded(
                              flex: otherFlex,
                              child: Container(color: Colors.amber.shade700),
                            ),
                          if (taxFlex > 0)
                            Expanded(
                              flex: taxFlex,
                              child: Container(color: Colors.teal),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _legendItem(Colors.blue, 'Energy', energyPct),
                      _legendItem(Colors.amber.shade700, 'FPA/QTA/Fees', otherPct),
                      _legendItem(Colors.teal, 'GST & Duties', taxPct),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                  const Divider(height: 20),
                  _row('Base Energy Charge', calculation.baseEnergyCharge),
                  _row('Fuel Price Adjustment (FPA)', calculation.fpaCharge),
                  _row('Quarterly Tariff Adj. (QTA)', calculation.qtaCharge),
                  if (calculation.fixedCharges > 0)
                    _row('Fixed Charges', calculation.fixedCharges),
                  if (calculation.meterRent > 0)
                    _row('Meter Rent', calculation.meterRent),
                  _row('GST & Electricity Duties', calculation.gstAndDuties),
                  const Divider(height: 20),
                  _row(
                    'Estimated Total Bill',
                    calculation.totalBill,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Summary'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _buildSummaryText()),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bill summary copied to clipboard.'),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save to History'),
                  onPressed: () async {
                    await HiveStorageService.saveBill(calculation);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulation saved to Hive.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}