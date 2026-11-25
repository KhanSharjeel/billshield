import 'package:flutter/material.dart';
import 'package:billshield/models/electricity_provider.dart';
import 'package:billshield/database/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultProvider = 'IESCO';
  bool _isThreePhase = false;
  bool _is6MonthLocked = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = await AppDatabase.instance.getSetting('provider');
    final threePhase = await AppDatabase.instance.getSetting('isThreePhase');
    final sixMonth = await AppDatabase.instance.getSetting('is6MonthUnprotectedLocked');
    if (mounted) {
      setState(() {
        if (provider != null) _defaultProvider = provider;
        if (threePhase != null) _isThreePhase = threePhase == 'true';
        if (sixMonth != null) _is6MonthLocked = sixMonth == 'true';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Info')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Default Electricity DISCO & Meter Settings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _defaultProvider,
                        decoration: const InputDecoration(
                          labelText: 'Selected Provider',
                        ),
                        items: ElectricityProvider.allProviders
                            .map((p) => DropdownMenuItem(
                                  value: p.code,
                                  child: Text('${p.code} — ${p.fullName}'),
                                ))
                            .toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setState(() => _defaultProvider = val);
                            await AppDatabase.instance.setSetting('provider', val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Three-Phase Meter Connection'),
                        subtitle: const Text(
                          'Applies 3-Phase higher meter rent (Rs. 100) and commercial/heavy load rules',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _isThreePhase,
                        onChanged: (val) async {
                          setState(() => _isThreePhase = val);
                          await AppDatabase.instance
                              .setSetting('isThreePhase', val.toString());
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('6-Month Unprotected Lock'),
                        subtitle: const Text(
                          'NEPRA Rule: Exceeding 200 units in recent months locks tariff to Unprotected',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _is6MonthLocked,
                        onChanged: (val) async {
                          setState(() => _is6MonthLocked = val);
                          await AppDatabase.instance
                              .setSetting('is6MonthUnprotectedLocked', val.toString());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'NEPRA Pakistani Tariff Rules',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: const [
                    Text(
                      '• Protected Consumers (≤ 200 kWh/month):\n'
                      '  Consistently consume <= 200 units per month for 6 consecutive months. Benefit from subsidized base energy rates (Rs. 11.69 to 14.16/u).\n\n'
                      '• 6-Month Unprotected Rule:\n'
                      '  Exceeding 200 units in any single month locks the consumer into Unprotected slab rates for the next 6 months.\n\n'
                      '• Unprotected Consumers (> 200 kWh/month):\n'
                      '  Crossing 200 units activates steep progressive slab rates (Rs. 23.59 up to 48.84/u).\n\n'
                      '• Peak Hours (TOU):\n'
                      '  Heavy appliances running during Peak Hours (6 PM to 10 PM) are billed at Rs. 48.00/kWh.\n\n'
                      '• Additional Charges:\n'
                      '  FPA (Fuel Price Adjustment), QTA (Quarterly Tariff Adjustment), 18% GST, PTV Fee (Rs. 35), and Meter Rent (Rs. 50 single-phase / Rs. 100 three-phase).',
                      style: TextStyle(height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Reset All Saved Workspace & Data'),
                  subtitle: const Text('Clears local storage & saved bill history'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset App Data?'),
                        content: const Text(
                          'This will clear all saved bills and restore default settings.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await AppDatabase.instance.clearAllBills();
                              await AppDatabase.instance.setSetting('provider', 'IESCO');
                              await AppDatabase.instance.setSetting('fpaRate', '2.50');
                              await AppDatabase.instance.setSetting('qtaRate', '1.75');
                              await AppDatabase.instance.setSetting('fixedCharges', '0.0');
                              await AppDatabase.instance.setSetting('isThreePhase', 'false');
                              await AppDatabase.instance.setSetting('is6MonthUnprotectedLocked', 'false');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('App data reset.')),
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shield, size: 36, color: Colors.teal),
                    SizedBox(height: 6),
                    Text(
                      'BillShield v1.0.0',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Offline-First Electricity Billing & Appliance Simulator',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
