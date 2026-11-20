import 'package:material_ui/material_ui.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';
import 'package:billshield/widgets/appliance_tile.dart';
import 'package:billshield/widgets/slab_status_banner.dart';
import 'package:billshield/screens/bill_breakdown_screen.dart';
import 'package:billshield/screens/saved_bills_screen.dart';

class HomeSimulatorScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const HomeSimulatorScreen({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  @override
  State<HomeSimulatorScreen> createState() => _HomeSimulatorScreenState();
}

class _HomeSimulatorScreenState extends State<HomeSimulatorScreen> {
  String _selectedProvider = NepraTariffService.providers.first;

  final List<ApplianceItem> _appliances = [
    const ApplianceItem(name: 'Ceiling Fan', watts: 75, quantity: 3, dailyHours: 10),
    const ApplianceItem(name: 'LED Lights', watts: 12, quantity: 6, dailyHours: 6),
    const ApplianceItem(name: 'Refrigerator', watts: 150, quantity: 1, dailyHours: 14),
  ];

  void _showAddApplianceDialog() {
    final nameController = TextEditingController();
    final wattsController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final hoursController = TextEditingController(text: '4');
    bool isPeak = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Appliance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Appliance Name'),
                ),
                TextField(
                  controller: wattsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Wattage (W)'),
                ),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Hours'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Runs in Peak Hours'),
                  value: isPeak,
                  onChanged: (val) => setDialogState(() => isPeak = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final watts = double.tryParse(wattsController.text) ?? 0;
                final qty = int.tryParse(qtyController.text) ?? 1;
                final hours = double.tryParse(hoursController.text) ?? 0;
                if (name.isNotEmpty && watts > 0 && qty > 0 && hours > 0) {
                  setState(() {
                    _appliances.add(
                      ApplianceItem(
                        name: name,
                        watts: watts,
                        quantity: qty,
                        dailyHours: hours,
                        isPeakHours: isPeak,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculation = NepraTariffService.calculateBill(
      provider: _selectedProvider,
      appliances: _appliances,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillShield'),
        actions: [
          if (widget.onThemeChanged != null)
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => widget.onThemeChanged!(!widget.isDarkMode),
            ),
          IconButton(
            tooltip: 'Saved Bills',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedBillsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddApplianceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Appliance'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedProvider,
            decoration: const InputDecoration(
              labelText: 'Electricity Provider (DISCO)',
              border: OutlineInputBorder(),
            ),
            items: NepraTariffService.providers
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedProvider = val);
            },
          ),
          const SizedBox(height: 12),
          SlabStatusBanner(
            totalUnits: calculation.totalUnits,
            isProtected: calculation.isProtected,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Monthly Bill'),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${calculation.totalBill.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${calculation.totalUnits.toStringAsFixed(1)} kWh / month',
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BillBreakdownScreen(calculation: calculation),
                        ),
                      );
                    },
                    child: const Text('Breakdown'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Simulated Appliances (${_appliances.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (_appliances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Tap + Appliance to simulate your monthly load.'),
              ),
            )
          else
            ...List.generate(_appliances.length, (index) {
              final item = _appliances[index];
              return ApplianceTile(
                item: item,
                onDelete: () => setState(() => _appliances.removeAt(index)),
                onPeakChanged: (peak) {
                  setState(() {
                    _appliances[index] = item.copyWith(isPeakHours: peak);
                  });
                },
              );
            }),
        ],
      ),
    );
  }
}