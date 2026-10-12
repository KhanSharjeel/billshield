import 'package:flutter/material.dart';
import '../models/nepra_engine.dart';

// --- APPLIANCE DATA MODEL ---
class ApplianceItem {
  String name;
  double wattage;
  int quantity;
  double hoursPerDay;

  ApplianceItem({
    required this.name,
    required this.wattage,
    required this.quantity,
    required this.hoursPerDay,
  });

  // (Watts * Quantity * Hours * 30 Days) / 1000 = kWh (Units) per month
  double get monthlyUnits => (wattage * quantity * hoursPerDay * 30) / 1000.0;
}

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();

  // --- STATE VARIABLES ---
  int _currentUnits = 0;
  double _fpaRate = 0.0;
  double _qtaRate = 0.0;
  final double _sanctionedLoad = 1.0;
  bool _isProtected = true;

  String _selectedProvider = 'IESCO (Islamabad)';
  final List<String> _providers = [
    'IESCO (Islamabad)',
    'LESCO (Lahore)',
    'K-Electric (Karachi)',
    'MEPCO (Multan)',
    'FESCO (Faisalabad)',
    'PESCO (Peshawar)',
    'GEPCO (Gujranwala)',
    'HESCO (Hyderabad)',
    'QESCO (Quetta)',
  ];

  final List<ApplianceItem> _appliances = [];
  Map<String, dynamic> _billBreakdown = {};

  @override
  void initState() {
    super.initState();
    _calculateBill();
  }

  void _calculateBill() {
    setState(() {
      _billBreakdown = NepraEngine.calculateMonthlyBill(
        consumedUnits: _currentUnits,
        isProtected: _isProtected,
        sanctionedLoadKw: _sanctionedLoad,
        fpaRate: _fpaRate,
        qtaRate: _qtaRate,
      );
    });
  }

  void _submitCalculation() {
    if (_formStateKey.currentState!.validate()) {
      _formStateKey.currentState!.save();
      _calculateBill();
    }
  }

  double get _totalApplianceUnits {
    return _appliances.fold(0, (sum, item) => sum + item.monthlyUnits);
  }

  // --- DIALOG FOR ADDING APPLIANCES ---
  void _showAddApplianceDialog() {
    String selectedPreset = 'Standard Bulb (50W)';
    final TextEditingController nameController = TextEditingController(text: 'Standard Bulb');
    final TextEditingController wattController = TextEditingController(text: '50');
    final TextEditingController qtyController = TextEditingController(text: '1');
    final TextEditingController hoursController = TextEditingController(text: '5');

    final Map<String, double> presets = {
      'LED Bulb (12W)': 12,
      'Standard Bulb (50W)': 50,
      'Ceiling Fan (80W)': 80,
      'Inverter AC 1.5 Ton (1200W)': 1200,
      'Standard AC 1.5 Ton (1800W)': 1800,
      'Refrigerator (250W)': 250,
      'Custom Device': 0,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Appliance"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedPreset,
                      items: presets.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(key),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedPreset = val;
                            if (val == 'Custom Device') {
                              nameController.text = '';
                              wattController.text = '';
                            } else {
                              // Extract name without the wattage in parenthesis
                              nameController.text = val.split(' (')[0];
                              wattController.text = presets[val]!.toInt().toString();
                            }
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Device Type'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Appliance Name'),
                    ),
                    TextField(
                      controller: wattController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Power (Watts)'),
                    ),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Usage (Hours)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final watts = double.tryParse(wattController.text) ?? 0;
                    final qty = int.tryParse(qtyController.text) ?? 1;
                    final hours = double.tryParse(hoursController.text) ?? 0;

                    if (name.isNotEmpty && watts > 0) {
                      setState(() {
                        _appliances.add(ApplianceItem(
                          name: name,
                          wattage: watts,
                          quantity: qty,
                          hoursPerDay: hours,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool inDangerZone = _billBreakdown['isDangerZone'] ?? false;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillShield Predictor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[

                // --- PROVIDER SELECTION ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Provider:", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedProvider,
                        underline: const SizedBox(), // Removes the default underline
                        items: _providers.map((String provider) {
                          return DropdownMenuItem<String>(
                            value: provider,
                            child: Text(provider),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProvider = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- DANGER ZONE WARNING ---
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: inDangerZone ? Colors.red.shade100 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.grey, blurRadius: 5.0, offset: Offset(0.0, 5.0))
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        inDangerZone ? "DANGER ZONE: Near 200 Units!" : "Status: Protected Consumer",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: inDangerZone ? Colors.red.shade900 : Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Estimated Bill: PKR ${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      Text("Current Load: $_currentUnits Units", style: const TextStyle(fontSize: 14.0)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- APPLIANCE SIMULATOR ---
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Appliance Simulator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28),
                            onPressed: _showAddApplianceDialog,
                          )
                        ],
                      ),
                      const Text("Calculate how devices impact your bill.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(),
                      if (_appliances.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text("Tap '+' to add devices (e.g. 50W Bulb)")),
                        ),
                      ..._appliances.asMap().entries.map((entry) {
                        int idx = entry.key;
                        ApplianceItem item = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text("${item.quantity}x ${item.name} (${item.wattage.toInt()}W)"),
                          subtitle: Text("${item.hoursPerDay} hrs/day = ${item.monthlyUnits.toStringAsFixed(1)} Units"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _appliances.removeAt(idx);
                              });
                            },
                          ),
                        );
                      }).toList(),
                      if (_appliances.isNotEmpty) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Simulator Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${_totalApplianceUnits.toStringAsFixed(1)} Units", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            icon: const Icon(Icons.sync),
                            label: const Text("Sync Simulator to Main Bill"),
                            onPressed: () {
                              setState(() {
                                _currentUnits = _totalApplianceUnits.round();
                                _calculateBill(); // Recalculate bill with synced units
                              });
                            },
                          ),
                        )
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- MANUAL UNIT INPUT & ADJUSTMENTS ---
                Form(
                  key: _formStateKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text("Manual Adjustment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _currentUnits.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Consumed Units',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flash_on),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null || value.isEmpty) ? 'Units required' : null,
                          onSaved: (value) => _currentUnits = int.tryParse(value ?? '') ?? 0,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                initialValue: _fpaRate.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'FPA Rate',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _fpaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: _qtaRate.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'QTA Rate',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _qtaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Calculate Bill'),
                            onPressed: () => _submitCalculation(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}