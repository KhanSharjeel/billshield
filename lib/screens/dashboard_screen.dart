import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';
import 'package:billshield/services/appliance_calculator.dart';
import 'package:billshield/database/app_database.dart';
import 'package:billshield/services/hive_storage_service.dart';
import 'package:billshield/widgets/provider_selector.dart';
import 'package:billshield/widgets/protected_status_card.dart';
import 'package:billshield/widgets/bill_summary_card.dart';
import 'package:billshield/widgets/quick_add_appliance.dart';
import 'package:billshield/widgets/appliance_tile.dart';
import 'package:billshield/widgets/bill_charges_section.dart';
import 'package:billshield/widgets/energy_category_chart.dart';
import 'package:billshield/screens/bill_breakdown_screen.dart';
import 'package:billshield/screens/history_screen.dart';
import 'package:billshield/screens/settings_screen.dart';
import 'package:billshield/screens/solar_screen.dart';
import 'package:billshield/screens/backup_screen.dart';
import 'package:billshield/screens/comparison_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const DashboardScreen({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedProvider = 'IESCO';
  double _fpaRate = 2.50;
  double _qtaRate = 1.75;
  double _fixedCharges = 0.0;
  bool _includeMeterRent = true;
  bool _includeTvFee = false;
  bool _isThreePhase = false;
  bool _is6MonthLocked = false;
  bool _isLoading = true;

  List<ApplianceItem> _appliances = [
    const ApplianceItem(
      name: 'Ceiling Fan',
      watts: 75,
      quantity: 3,
      dailyHours: 10,
    ),
    const ApplianceItem(
      name: 'LED Bulbs',
      watts: 12,
      quantity: 6,
      dailyHours: 6,
    ),
    const ApplianceItem(
      name: 'Refrigerator',
      watts: 160,
      quantity: 1,
      dailyHours: 14,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    try {
      final hiveWorkspace = HiveStorageService.loadWorkspace();
      final savedProvider = hiveWorkspace?['provider'] ??
          await AppDatabase.instance.getSetting('provider');
      final savedFpa = hiveWorkspace?['fpaRate']?.toString() ??
          await AppDatabase.instance.getSetting('fpaRate');
      final savedQta = hiveWorkspace?['qtaRate']?.toString() ??
          await AppDatabase.instance.getSetting('qtaRate');
      final savedFixed = hiveWorkspace?['fixedCharges']?.toString() ??
          await AppDatabase.instance.getSetting('fixedCharges');
      final savedMeterRent = hiveWorkspace?['includeMeterRent']?.toString() ??
          await AppDatabase.instance.getSetting('includeMeterRent');
      final savedTvFee = hiveWorkspace?['includeTvFee']?.toString() ??
          await AppDatabase.instance.getSetting('includeTvFee');
      final savedThreePhase = hiveWorkspace?['isThreePhase']?.toString() ??
          await AppDatabase.instance.getSetting('isThreePhase');
      final saved6MonthLocked = hiveWorkspace?['is6MonthUnprotectedLocked']?.toString() ??
          await AppDatabase.instance.getSetting('is6MonthUnprotectedLocked');

      List<ApplianceItem> dbAppliances = [];
      if (hiveWorkspace != null &&
          (hiveWorkspace['appliances'] as List<ApplianceItem>).isNotEmpty) {
        dbAppliances = hiveWorkspace['appliances'] as List<ApplianceItem>;
      } else {
        dbAppliances = await AppDatabase.instance.getActiveAppliances();
      }

      if (mounted) {
        setState(() {
          if (savedProvider != null &&
              NepraTariffService.providers.contains(savedProvider)) {
            _selectedProvider = savedProvider;
          }
          if (savedFpa != null) _fpaRate = double.tryParse(savedFpa) ?? 2.50;
          if (savedQta != null) _qtaRate = double.tryParse(savedQta) ?? 1.75;
          if (savedFixed != null) _fixedCharges = double.tryParse(savedFixed) ?? 0.0;
          if (savedMeterRent != null) _includeMeterRent = savedMeterRent == 'true';
          if (savedTvFee != null) _includeTvFee = savedTvFee == 'true';
          if (savedThreePhase != null) _isThreePhase = savedThreePhase == 'true';
          if (saved6MonthLocked != null) _is6MonthLocked = saved6MonthLocked == 'true';
          if (dbAppliances.isNotEmpty) _appliances = List<ApplianceItem>.from(dbAppliances);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _persistState() async {
    await AppDatabase.instance.setSetting('provider', _selectedProvider);
    await AppDatabase.instance.setSetting('fpaRate', _fpaRate.toString());
    await AppDatabase.instance.setSetting('qtaRate', _qtaRate.toString());
    await AppDatabase.instance.setSetting('fixedCharges', _fixedCharges.toString());
    await AppDatabase.instance.setSetting('includeMeterRent', _includeMeterRent.toString());
    await AppDatabase.instance.setSetting('includeTvFee', _includeTvFee.toString());
    await AppDatabase.instance.setSetting('isThreePhase', _isThreePhase.toString());
    await AppDatabase.instance.setSetting('is6MonthUnprotectedLocked', _is6MonthLocked.toString());
    await AppDatabase.instance.saveActiveAppliances(_appliances);

    await HiveStorageService.saveWorkspace(
      provider: _selectedProvider,
      appliances: _appliances,
      fpaRate: _fpaRate,
      qtaRate: _qtaRate,
      fixedCharges: _fixedCharges,
      includeMeterRent: _includeMeterRent,
      includeTvFee: _includeTvFee,
      isThreePhase: _isThreePhase,
      is6MonthUnprotectedLocked: _is6MonthLocked,
    );
  }

  void _removeApplianceWithUndo(int index) {
    final removedItem = _appliances[index];
    setState(() {
      _appliances.removeAt(index);
    });
    _persistState();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removedItem.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _appliances.insert(index, removedItem);
            });
            _persistState();
          },
        ),
      ),
    );
  }

  void _clearAllWithUndo() {
    if (_appliances.isEmpty) return;
    final previousList = List<ApplianceItem>.from(_appliances);
    setState(() {
      _appliances.clear();
    });
    _persistState();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared all appliances'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _appliances = previousList;
            });
            _persistState();
          },
        ),
      ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Edit Appliance' : 'Add Custom Appliance',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance Name',
                    hintText: 'e.g. Inverter AC, Water Pump',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: wattsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Wattage (W)',
                          hintText: '75',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: '1',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Daily Operating Hours (0–24)',
                    hintText: '6.0',
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Runs in Peak Hours (6 PM – 10 PM)'),
                  subtitle: const Text(
                    'Applies Peak TOU tariff rate (Rs. 48.00/kWh)',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: isPeak,
                  onChanged: (val) => setModalState(() => isPeak = val),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final watts = double.tryParse(wattsController.text) ?? 0;
                        final qty = int.tryParse(qtyController.text) ?? 1;
                        final hours = double.tryParse(hoursController.text) ?? 0;

                        if (name.isNotEmpty && watts > 0 && qty > 0 && hours > 0) {
                          final newItem = ApplianceItem(
                            id: existing?.id,
                            name: name,
                            watts: watts,
                            quantity: qty,
                            dailyHours: hours.clamp(0.1, 24.0),
                            isPeakHours: isPeak,
                          );
                          setState(() {
                            if (isEditing) {
                              _appliances[index] = newItem;
                            } else {
                              _appliances.add(newItem);
                            }
                          });
                          _persistState();
                          Navigator.pop(ctx);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please enter valid positive values.'),
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Add Appliance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final calculation = NepraTariffService.calculateBill(
      provider: _selectedProvider,
      appliances: _appliances,
      fpaRatePerUnit: _fpaRate,
      qtaRatePerUnit: _qtaRate,
      includeMeterRent: _includeMeterRent,
      includeTvFee: _includeTvFee,
      fixedChargesRate: _fixedCharges,
      isThreePhase: _isThreePhase,
      is6MonthUnprotectedLocked: _is6MonthLocked,
    );

    final actionableSuggestion =
        ApplianceCalculator.getTopActionableSuggestion(
      _appliances,
      calculation.totalUnits,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.electric_bolt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('BillShield'),
          ],
        ),
        actions: [
          if (widget.onThemeChanged != null)
            IconButton(
              tooltip: 'Toggle Dark/Light Mode',
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => widget.onThemeChanged!(!widget.isDarkMode),
            ),
          IconButton(
            tooltip: 'Saved Bills History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadPersistedData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplianceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Appliance'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              ProviderSelector(
                selectedProviderCode: _selectedProvider,
                onProviderChanged: (p) {
                  setState(() => _selectedProvider = p.code);
                  _persistState();
                },
              ),
              const SizedBox(height: 10),
              // Advanced Modules Quick Navigation Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.wb_sunny, size: 16, color: Colors.amber),
                      label: const Text('Solar Net-Metering', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SolarScreen(currentBill: calculation),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.battery_charging_full, size: 16, color: Colors.blue),
                      label: const Text('UPS & Battery Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BackupScreen(appliances: _appliances),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.compare_arrows, size: 16, color: Colors.teal),
                      label: const Text('What-If Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComparisonScreen(currentBill: calculation),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ProtectedStatusCard(
                totalUnits: calculation.totalUnits,
                isProtected: calculation.isProtected,
                is6MonthLocked: _is6MonthLocked,
                isThreePhase: _isThreePhase,
                excessUnits: calculation.excessUnitsOverProtected,
                potentialSavings: calculation.estimatedSavingsIfProtected,
              ),
              const SizedBox(height: 10),
              BillSummaryCard(
                calculation: calculation,
                onBreakdownPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BillBreakdownScreen(calculation: calculation),
                    ),
                  );
                },
              ),
              if (actionableSuggestion != null && calculation.totalUnits > 200) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.amber.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              color: Colors.amber.shade900,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                actionableSuggestion.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          actionableSuggestion.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown.shade900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              final target = actionableSuggestion.targetAppliance;
                              final updated = target.copyWith(
                                dailyHours: actionableSuggestion.newDailyHours,
                              );
                              setState(() {
                                _appliances[actionableSuggestion.applianceIndex] =
                                    updated;
                              });
                              _persistState();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reduced ${target.name} to ${actionableSuggestion.newDailyHours}h/day.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Apply Suggestion'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              EnergyCategoryChart(appliances: _appliances),
              const SizedBox(height: 10),
              BillChargesSection(
                fpaRate: _fpaRate,
                qtaRate: _qtaRate,
                fixedCharges: _fixedCharges,
                includeMeterRent: _includeMeterRent,
                includeTvFee: _includeTvFee,
                isThreePhase: _isThreePhase,
                is6MonthLocked: _is6MonthLocked,
                onApplyChanges: ({
                  required double fpaRate,
                  required double qtaRate,
                  required double fixedCharges,
                  required bool includeMeterRent,
                  required bool includeTvFee,
                  required bool isThreePhase,
                  required bool is6MonthLocked,
                }) {
                  setState(() {
                    _fpaRate = fpaRate;
                    _qtaRate = qtaRate;
                    _fixedCharges = fixedCharges;
                    _includeMeterRent = includeMeterRent;
                    _includeTvFee = includeTvFee;
                    _isThreePhase = isThreePhase;
                    _is6MonthLocked = is6MonthLocked;
                  });
                  _persistState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tariff rates updated.')),
                  );
                },
              ),
              const SizedBox(height: 16),
              QuickAddApplianceSection(
                onAddPreset: (preset) {
                  setState(() => _appliances.add(preset));
                  _persistState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Added ${preset.name} (${preset.watts.toInt()}W)'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onApplyHouseholdBundle: (bundle) {
                  setState(() {
                    _appliances = List<ApplianceItem>.from(bundle);
                  });
                  _persistState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loaded household preset bundle.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Simulated Appliances (${_appliances.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_appliances.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear All'),
                      onPressed: _clearAllWithUndo,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_appliances.isEmpty)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.power_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Appliances Simulated',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap quick-add buttons above or tap "+ Add Appliance" to build your electricity load.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
                    onTap: () =>
                        _showApplianceDialog(existing: item, index: index),
                    onDelete: () => _removeApplianceWithUndo(index),
                    onQuantityChanged: (newQty) {
                      setState(() {
                        _appliances[index] = item.copyWith(quantity: newQty);
                      });
                      _persistState();
                    },
                    onPeakChanged: (isPeak) {
                      setState(() {
                        _appliances[index] = item.copyWith(isPeakHours: isPeak);
                      });
                      _persistState();
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
