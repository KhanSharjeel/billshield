import 'package:material_ui/material_ui.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/hive_storage_service.dart';
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
  double _fpaRate = 2.50;
  double _qtaRate = 1.75;
  double _fixedCharges = 0.0;
  bool _includeMeterRent = true;

  late final TextEditingController _fpaController;
  late final TextEditingController _qtaController;
  late final TextEditingController _fixedController;

  static const List<ApplianceItem> _presets = [
    ApplianceItem(
      name: '1.5T Inverter AC',
      watts: 1500,
      quantity: 1,
      dailyHours: 6,
      isPeakHours: true,
    ),
    ApplianceItem(
      name: 'Ceiling Fan',
      watts: 75,
      quantity: 1,
      dailyHours: 12,
    ),
    ApplianceItem(
      name: 'Refrigerator',
      watts: 160,
      quantity: 1,
      dailyHours: 14,
    ),
    ApplianceItem(
      name: 'Electric Iron',
      watts: 1200,
      quantity: 1,
      dailyHours: 1,
    ),
    ApplianceItem(
      name: 'Water Pump',
      watts: 746,
      quantity: 1,
      dailyHours: 1,
    ),
    ApplianceItem(
      name: 'LED TV',
      watts: 85,
      quantity: 1,
      dailyHours: 4,
      isPeakHours: true,
    ),
  ];

  List<ApplianceItem> _appliances = [
    const ApplianceItem(
      name: 'Ceiling Fan',
      watts: 75,
      quantity: 3,
      dailyHours: 10,
    ),
    const ApplianceItem(
      name: 'LED Lights',
      watts: 12,
      quantity: 6,
      dailyHours: 6,
    ),
    const ApplianceItem(
      name: 'Refrigerator',
      watts: 150,
      quantity: 1,
      dailyHours: 14,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final saved = HiveStorageService.loadWorkspace();
    if (saved != null) {
      final loadedProvider = saved['provider'] as String?;
      if (loadedProvider != null &&
          NepraTariffService.providers.contains(loadedProvider)) {
        _selectedProvider = loadedProvider;
      }
      final loadedAppliances =
          saved['appliances'] as List<ApplianceItem>? ?? const [];
      if (loadedAppliances.isNotEmpty) {
        _appliances = List<ApplianceItem>.from(loadedAppliances);
      }
      _fpaRate = (saved['fpaRate'] as double?) ?? 2.50;
      _qtaRate = (saved['qtaRate'] as double?) ?? 1.75;
      _fixedCharges = (saved['fixedCharges'] as double?) ?? 0.0;
      _includeMeterRent = (saved['includeMeterRent'] as bool?) ?? true;
    }

    _fpaController = TextEditingController(text: _fpaRate.toStringAsFixed(2));
    _qtaController = TextEditingController(text: _qtaRate.toStringAsFixed(2));
    _fixedController =
        TextEditingController(text: _fixedCharges.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _fpaController.dispose();
    _qtaController.dispose();
    _fixedController.dispose();
    super.dispose();
  }

  void _persistWorkspace() {
    HiveStorageService.saveWorkspace(
      provider: _selectedProvider,
      appliances: _appliances,
      fpaRate: _fpaRate,
      qtaRate: _qtaRate,
      fixedCharges: _fixedCharges,
      includeMeterRent: _includeMeterRent,
    );
  }

  void _applyTariffSettings() {
    final parsedFpa = double.tryParse(_fpaController.text.trim());
    final parsedQta = double.tryParse(_qtaController.text.trim());
    final parsedFixed = double.tryParse(_fixedController.text.trim());
    setState(() {
      if (parsedFpa != null && parsedFpa >= 0) _fpaRate = parsedFpa;
      if (parsedQta != null && parsedQta >= 0) _qtaRate = parsedQta;
      if (parsedFixed != null && parsedFixed >= 0) _fixedCharges = parsedFixed;
    });
    _persistWorkspace();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tariff adjustments updated.')),
    );
  }

  void _showApplianceDialog({ApplianceItem? existing, int? index}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final wattsController = TextEditingController(
      text: existing != null ? existing.watts.toStringAsFixed(0) : '',
    );
    final qtyController = TextEditingController(
      text: (existing?.quantity ?? 1).toString(),
    );
    final hoursController = TextEditingController(
      text: existing != null ? existing.dailyHours.toStringAsFixed(1) : '4.0',
    );
    bool isPeak = existing?.isPeakHours ?? false;
    final isEditing = existing != null && index != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Appliance' : 'Add Appliance'),
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
                  final updated = ApplianceItem(
                    name: name,
                    watts: watts,
                    quantity: qty,
                    dailyHours: hours,
                    isPeakHours: isPeak,
                  );
                  setState(() {
                    if (isEditing) {
                      _appliances[index] = updated;
                    } else {
                      _appliances.add(updated);
                    }
                  });
                  _persistWorkspace();
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
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
      fpaRatePerUnit: _fpaRate,
      qtaRatePerUnit: _qtaRate,
      includeMeterRent: _includeMeterRent,
      fixedChargesRate: _fixedCharges,
    );

    final slabProgress = (calculation.totalUnits / 200.0).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillShield'),
        actions: [
          if (widget.onThemeChanged != null)
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
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
        onPressed: () => _showApplianceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Custom'),
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
              if (val != null) {
                setState(() => _selectedProvider = val);
                _persistWorkspace();
              }
            },
          ),
          const SizedBox(height: 12),
          SlabStatusBanner(
            totalUnits: calculation.totalUnits,
            isProtected: calculation.isProtected,
            excessUnits: calculation.excessUnitsOverProtected,
            potentialSavings: calculation.estimatedSavingsIfProtected,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Monthly Bill'),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              'Rs. ${calculation.totalBill.toStringAsFixed(0)}',
                              key: ValueKey(calculation.totalBill.round()),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
                              builder: (_) => BillBreakdownScreen(
                                calculation: calculation,
                              ),
                            ),
                          );
                        },
                        child: const Text('Breakdown'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: slabProgress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Protected Slab Progress: ${calculation.totalUnits.toStringAsFixed(0)} / 200 units',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: const Text('FPA, QTA & Bill Charges'),
              subtitle: Text(
                'FPA: Rs. ${_fpaRate.toStringAsFixed(2)} • QTA: Rs. ${_qtaRate.toStringAsFixed(2)} • '
                    'Meter Rent: ${_includeMeterRent ? "On" : "Off"}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fpaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'FPA (Rs./u)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _qtaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'QTA (Rs./u)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fixedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Fixed (Rs.)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include Meter Rent (Rs. 50)'),
                  value: _includeMeterRent,
                  onChanged: (v) {
                    setState(() => _includeMeterRent = v);
                    _persistWorkspace();
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: _applyTariffSettings,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Quick-Add Pakistani Appliances',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return ActionChip(
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text('${preset.name} (${preset.watts.toInt()}W)'),
                  onPressed: () {
                    setState(() => _appliances.add(preset));
                    _persistWorkspace();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Simulated Appliances (${_appliances.length}) • Tap to edit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (_appliances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tap a preset chip above or + Custom to simulate your load.',
                ),
              ),
            )
          else
            ...List.generate(_appliances.length, (index) {
              final item = _appliances[index];
              final applianceCost =
              NepraTariffService.estimateApplianceMonthlyCost(
                item: item,
                isProtected: calculation.isProtected,
                fpaRatePerUnit: _fpaRate,
                qtaRatePerUnit: _qtaRate,
              );
              return ApplianceTile(
                item: item,
                estimatedMonthlyCost: applianceCost,
                onTap: () => _showApplianceDialog(existing: item, index: index),
                onDelete: () {
                  setState(() => _appliances.removeAt(index));
                  _persistWorkspace();
                },
                onPeakChanged: (peak) {
                  setState(() {
                    _appliances[index] = item.copyWith(isPeakHours: peak);
                  });
                  _persistWorkspace();
                },
              );
            }),
        ],
      ),
    );
  }
}