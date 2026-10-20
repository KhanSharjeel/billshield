import 'package:flutter/material.dart';
import '../models/nepra_engine.dart';

// --- APPLIANCE DATA MODEL ---
class ApplianceItem {
  String name;
  double wattage;
  int quantity;
  double offPeakHoursPerDay;
  double peakHoursPerDay;

  ApplianceItem({
    required this.name,
    required this.wattage,
    required this.quantity,
    required this.offPeakHoursPerDay,
    required this.peakHoursPerDay,
  });

  // Now dynamically accepts the exact number of days in the selected billing cycle!
  double getMonthlyOffPeakUnits(int days) => (wattage * quantity * offPeakHoursPerDay * days) / 1000.0;
  double getMonthlyPeakUnits(int days) => (wattage * quantity * peakHoursPerDay * days) / 1000.0;
}

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();

  // --- STATE VARIABLES ---
  double _fpaRate = 0.0;
  double _qtaRate = 0.0;
  double _sanctionedLoad = 1.0;
  bool _isProtected = true;

  // --- DATE VARIABLES (Billing Cycle) ---
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

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

  // Calculates exact days between selected dates
  int get _billingDays {
    int days = _endDate.difference(_startDate).inDays + 1;
    return days > 0 ? days : 1; // Prevent negative or zero days
  }

  // --- DYNAMIC PEAK HOURS TEXT ---
  String get _peakHoursText {
    if (_selectedProvider.contains('K-Electric')) {
      return "Peak Hours: 6:30 PM–10:30 PM (Apr–Oct)  •  6:00 PM–10:00 PM (Nov–Mar)";
    } else {
      return "Peak Hours: 5 PM–9 PM (Dec–Feb)  •  6 PM–10 PM (Mar–May/Sep–Nov)  •  7 PM–11 PM (Jun–Aug)";
    }
  }

  double get _totalOffPeakUnits =>
      _appliances.fold(0, (sum, item) => sum + item.getMonthlyOffPeakUnits(_billingDays));
  double get _totalPeakUnits =>
      _appliances.fold(0, (sum, item) => sum + item.getMonthlyPeakUnits(_billingDays));

  void _calculateBill() {
    setState(() {
      _billBreakdown = NepraEngine.calculateMonthlyBill(
        offPeakUnits: _totalOffPeakUnits,
        peakUnits: _totalPeakUnits,
        isProtected: _isProtected,
        sanctionedLoadKw: _sanctionedLoad,
        provider: _selectedProvider,
        fpaRate: _fpaRate,
        qtaRate: _qtaRate,
      );
    });
  }

  void _submitAdjustments() {
    if (_formStateKey.currentState!.validate()) {
      _formStateKey.currentState!.save();
      _calculateBill();
    }
  }

  // --- CALENDAR DATE PICKER ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          // Ensure start date is not after end date
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
        _calculateBill(); // Recalculate bill with new date length
      });
    }
  }

  // --- DIALOG FOR ADDING APPLIANCES ---
  void _showAddApplianceDialog() {
    String selectedPreset = 'Standard Bulb (50W)';
    final TextEditingController nameController = TextEditingController(text: 'Standard Bulb');
    final TextEditingController wattController = TextEditingController(text: '50');
    final TextEditingController qtyController = TextEditingController(text: '1');
    final TextEditingController offPeakController = TextEditingController(text: '4');
    final TextEditingController peakController = TextEditingController(text: '2');

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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: wattController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Power (W)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text("Usage Profile",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: offPeakController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Off-Peak Hrs'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: peakController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Peak Hrs'),
                          ),
                        ),
                      ],
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final watts = double.tryParse(wattController.text) ?? 0;
                    final qty = int.tryParse(qtyController.text) ?? 1;
                    final offPeak = double.tryParse(offPeakController.text) ?? 0;
                    final peak = double.tryParse(peakController.text) ?? 0;

                    if (name.isNotEmpty && watts > 0 && (offPeak > 0 || peak > 0)) {
                      setState(() {
                        _appliances.add(ApplianceItem(
                          name: name,
                          wattage: watts,
                          quantity: qty,
                          offPeakHoursPerDay: offPeak,
                          peakHoursPerDay: peak,
                        ));
                        _calculateBill();
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
    final bool isToU = _billBreakdown['isToU'] ?? false;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;
    final double finalUnits = _billBreakdown['totalUnits'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillShield Predictor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8), // Optional rounded corners for logo
                child: Image.asset(
                  'images/logo3.png', // Logo path (must match pubspec.yaml)
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.amber),
                ),
              ),
            ),
          ),
        ],
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
                        underline: const SizedBox(),
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
                              _calculateBill();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // DYNAMIC PEAK HOURS TEXT
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _peakHoursText,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- BILLING CYCLE DATES ---
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Billing Start", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Text("${_startDate.day}/${_startDate.month}/${_startDate.year}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text("$_billingDays Days", style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Billing End", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("${_endDate.day}/${_endDate.month}/${_endDate.year}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.event, size: 16, color: Colors.teal),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- STATUS DASHBOARD ---
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: finalUnits == 0
                        ? Colors.grey.shade100
                        : (inDangerZone ? Colors.red.shade100 : Colors.teal.shade50),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5.0, offset: Offset(0.0, 5.0))
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        finalUnits == 0
                            ? "Status: No Active Load"
                            : (isToU
                            ? "Status: ToU (Peak/Off-Peak)"
                            : (inDangerZone
                            ? "DANGER ZONE: Near 200 Units!"
                            : "Status: Standard Slab Consumer")),
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: finalUnits == 0
                              ? Colors.grey.shade800
                              : (inDangerZone ? Colors.red.shade900 : Colors.teal.shade900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Estimated Bill: PKR ${total.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      Text("Generated Load: ${finalUnits.toStringAsFixed(1)} Units",
                          style: const TextStyle(fontSize: 14.0)),
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
                          const Text("Appliance Simulator",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28),
                            onPressed: _showAddApplianceDialog,
                          )
                        ],
                      ),
                      const Text("Your bill is generated automatically from this list.",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(),
                      if (_appliances.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text("Tap '+' to power on appliances")),
                        ),
                      ..._appliances.asMap().entries.map((entry) {
                        int idx = entry.key;
                        ApplianceItem item = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text("${item.quantity}x ${item.name} (${item.wattage.toInt()}W)"),
                          subtitle: Text(
                              "Off-Peak: ${item.getMonthlyOffPeakUnits(_billingDays).toStringAsFixed(1)}U | Peak: ${item.getMonthlyPeakUnits(_billingDays).toStringAsFixed(1)}U"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _appliances.removeAt(idx);
                                _calculateBill();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- ACCOUNT & TARIFF ADJUSTMENTS ---
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
                        const Text("Account Details & Adjustments",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _sanctionedLoad.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Sanctioned Load (kW)',
                            border: OutlineInputBorder(),
                            helperText: 'Loads ≥ 5kW trigger ToU (Peak) billing.',
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _sanctionedLoad = double.tryParse(value ?? '') ?? 1.0,
                        ),
                        const SizedBox(height: 16),

                        // Explanation Box
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "FPA (Fuel Cost) & QTA (Maintenance) change monthly. Check your physical bill for this month's exact rates to get a 100% accurate prediction.",
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                initialValue: _fpaRate.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'FPA Rate (Fuel)',
                                    hintText: 'e.g. 2.5',
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _fpaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: _qtaRate.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'QTA Rate (Maint.)',
                                    hintText: 'e.g. 1.2',
                                    border: OutlineInputBorder()),
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
                                backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            child: const Text('Apply Tariffs & Calculate'),
                            onPressed: () => _submitAdjustments(),
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