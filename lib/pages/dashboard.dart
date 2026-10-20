import 'package:flutter/material.dart';
import '../models/nepra_engine.dart';

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

  double getMonthlyOffPeakUnits(int days) => (wattage * quantity * offPeakHoursPerDay * days) / 1000.0;
  double getMonthlyPeakUnits(int days) => (wattage * quantity * peakHoursPerDay * days) / 1000.0;
}

class Dashboard extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const Dashboard({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();

  double _fpaRate = 0.0;
  double _qtaRate = 0.0;
  double _sanctionedLoad = 1.0;
  bool _isProtected = true;

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

  int get _billingDays {
    int days = _endDate.difference(_startDate).inDays + 1;
    return days > 0 ? days : 1;
  }

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
      if (_appliances.isNotEmpty) {
        _showBillDetailsDialog();
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkTheme
                ? const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black)
                : const ColorScheme.light(primary: Colors.teal, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
        _calculateBill();
      });
    }
  }

  Widget _buildDetailRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("PKR ${amount.toStringAsFixed(2)}",
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.teal)),
        ],
      ),
    );
  }

  void _showBillDetailsDialog() {
    final double energy = _billBreakdown['energyCharge'] ?? 0.0;
    final double fixed = _billBreakdown['fixedCharge'] ?? 0.0;
    final double fpa = _billBreakdown['fpaCharge'] ?? 0.0;
    final double qta = _billBreakdown['qtaCharge'] ?? 0.0;
    final double duty = _billBreakdown['electricityDuty'] ?? 0.0;
    final double gst = _billBreakdown['gst'] ?? 0.0;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.teal),
              SizedBox(width: 8),
              Text("Itemized Breakdown", style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Energy Charges", energy),
                _buildDetailRow("Fixed Charges (Load)", fixed),
                _buildDetailRow("FPA Surcharge", fpa),
                _buildDetailRow("QTA Surcharge", qta),
                _buildDetailRow("Electricity Duty (1.5%)", duty),
                _buildDetailRow("GST (18%)", gst),
                const Divider(height: 24, thickness: 1.5),
                _buildDetailRow("Grand Total", total, isBold: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }

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
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final bool inDangerZone = _billBreakdown['isDangerZone'] ?? false;
    final bool isToU = _billBreakdown['isToU'] ?? false;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;
    final double finalUnits = _billBreakdown['totalUnits'] ?? 0.0;

    final Color borderColor = isDarkTheme ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillShield Predictor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode, size: 20),
              Switch(
                value: isDarkTheme,
                onChanged: widget.onThemeChanged,
                activeColor: Colors.tealAccent,
                activeTrackColor: Colors.teal.shade700,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.teal.shade300,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/logo3.png',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
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

                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.access_time, size: 14, color: isDarkTheme ? Colors.tealAccent : Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _peakHoursText,
                          style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
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
                              Text("Billing Start", style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.grey.shade400 : Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: isDarkTheme ? Colors.tealAccent : Colors.teal),
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
                        child: Text("$_billingDays Days", style: TextStyle(fontSize: 11, color: isDarkTheme ? Colors.tealAccent : Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Billing End", style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.grey.shade400 : Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("${_endDate.day}/${_endDate.month}/${_endDate.year}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.event, size: 16, color: isDarkTheme ? Colors.tealAccent : Colors.teal),
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

                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: finalUnits == 0
                        ? (isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade100)
                        : (inDangerZone
                        ? (isDarkTheme ? Colors.red.shade900 : Colors.red.shade100)
                        : (isDarkTheme ? Colors.teal.shade900 : Colors.teal.shade50)),
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
                              ? (isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade800)
                              : (inDangerZone
                              ? (isDarkTheme ? Colors.red.shade100 : Colors.red.shade900)
                              : (isDarkTheme ? Colors.tealAccent : Colors.teal.shade900)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Estimated Bill: PKR ${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: finalUnits == 0
                                ? (isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade800)
                                : (inDangerZone
                                ? (isDarkTheme ? Colors.red.shade100 : Colors.red.shade900)
                                : (isDarkTheme ? Colors.tealAccent : Colors.teal.shade900)),
                          )),
                      Text("Generated Load: ${finalUnits.toStringAsFixed(1)} Units",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: finalUnits == 0
                                ? (isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700)
                                : (inDangerZone
                                ? (isDarkTheme ? Colors.red.shade200 : Colors.red.shade900)
                                : (isDarkTheme ? Colors.tealAccent.shade100 : Colors.teal.shade800)),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
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
                            icon: Icon(Icons.add_circle, color: isDarkTheme ? Colors.tealAccent : Colors.teal, size: 28),
                            onPressed: _showAddApplianceDialog,
                          )
                        ],
                      ),
                      Text("Your bill is generated automatically from this list.",
                          style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.grey.shade400 : Colors.grey)),
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

                Form(
                  key: _formStateKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text("Account Details & Adjustments",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Sanctioned Load with input validation
                        TextFormField(
                          initialValue: _sanctionedLoad.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Sanctioned Load (kW)',
                            border: OutlineInputBorder(),
                            helperText: 'Loads ≥ 5kW trigger ToU (Peak) billing.',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter load';
                            double? load = double.tryParse(value);
                            if (load == null || load <= 0 || load > 50) return 'Must be between 0.1 and 50 kW';
                            return null;
                          },
                          onSaved: (value) => _sanctionedLoad = double.tryParse(value ?? '') ?? 1.0,
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isDarkTheme ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: isDarkTheme ? Colors.blue.shade700 : Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: isDarkTheme ? Colors.blueAccent : Colors.blue.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "FPA (Fuel Cost) & QTA (Maintenance) change monthly. Check your physical bill for this month's exact rates to get a 100% accurate prediction.",
                                  style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: <Widget>[
                            // FPA Rate with input validation
                            Expanded(
                              child: TextFormField(
                                initialValue: _fpaRate.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'FPA Rate (Fuel)',
                                    hintText: 'e.g. 2.5',
                                    border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  double? fpa = double.tryParse(value);
                                  if (fpa == null || fpa < -50 || fpa > 100) return 'Range: -50 to 100';
                                  return null;
                                },
                                onSaved: (value) => _fpaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // QTA Rate with input validation
                            Expanded(
                              child: TextFormField(
                                initialValue: _qtaRate.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'QTA Rate (Maint.)',
                                    hintText: 'e.g. 1.2',
                                    border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  double? qta = double.tryParse(value);
                                  if (qta == null || qta < -50 || qta > 100) return 'Range: -50 to 100';
                                  return null;
                                },
                                onSaved: (value) => _qtaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Apply Tariffs & Calculate'),
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