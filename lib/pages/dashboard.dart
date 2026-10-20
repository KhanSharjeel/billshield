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

  double get monthlyOffPeakUnits => (wattage * quantity * offPeakHoursPerDay * 30) / 1000.0;
  double get monthlyPeakUnits => (wattage * quantity * peakHoursPerDay * 30) / 1000.0;
  double get totalMonthlyUnits => monthlyOffPeakUnits + monthlyPeakUnits;
}

class Dashboard extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const Dashboard({
    Key? key,
    this.currentThemeMode = ThemeMode.system,
    this.onThemeModeChanged,
  }) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();

  late AnimationController _resetSpinController;

  late TextEditingController _sanctionedLoadController;
  late TextEditingController _fpaController;
  late TextEditingController _qtaController;

  // --- STATE VARIABLES ---
  double _fpaRate = 0.0;
  double _qtaRate = 0.0;
  double _sanctionedLoad = 1.0;
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

  final List<ApplianceItem> _appliances = [
    ApplianceItem(
      name: 'Inverter AC 1.5 Ton',
      wattage: 1200,
      quantity: 1,
      offPeakHoursPerDay: 4,
      peakHoursPerDay: 2,
    ),
  ];
  Map<String, dynamic> _billBreakdown = {};

  @override
  void initState() {
    super.initState();

    _resetSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _sanctionedLoadController = TextEditingController(text: _sanctionedLoad.toString());
    _fpaController = TextEditingController(text: _fpaRate.toString());
    _qtaController = TextEditingController(text: _qtaRate.toString());

    _calculateBill();
  }

  @override
  void dispose() {
    _resetSpinController.dispose();
    _sanctionedLoadController.dispose();
    _fpaController.dispose();
    _qtaController.dispose();
    super.dispose();
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
      _appliances.fold(0, (sum, item) => sum + item.monthlyOffPeakUnits);
  double get _totalPeakUnits =>
      _appliances.fold(0, (sum, item) => sum + item.monthlyPeakUnits);
  double get _totalUnits => _totalOffPeakUnits + _totalPeakUnits;

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

  void _resetDashboard() {
    _resetSpinController.forward(from: 0.0);
    setState(() {
      _fpaRate = 0.0;
      _qtaRate = 0.0;
      _sanctionedLoad = 1.0;
      _isProtected = true;
      _selectedProvider = 'IESCO (Islamabad)';
      _appliances.clear();

      _sanctionedLoadController.text = '1.0';
      _fpaController.text = '0.0';
      _qtaController.text = '0.0';

      _calculateBill();
    });
  }

  void _onProviderChanged(String? newProvider) {
    if (newProvider != null && newProvider != _selectedProvider) {
      setState(() {
        _selectedProvider = newProvider;
        _calculateBill();
      });
    }
  }

  void _submitAdjustments() {
    _resetSpinController.forward(from: 0.0);
    if (_formStateKey.currentState!.validate()) {
      _formStateKey.currentState!.save();
      _calculateBill();
    }
  }

  IconData _getApplianceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('inverter') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('bulb') || lower.contains('led') || lower.contains('light')) {
      return Icons.lightbulb_outline_rounded;
    } else if (lower.contains('fan') || lower.contains('ceiling')) {
      return Icons.toys_rounded;
    } else if (lower.contains('refrigerator') || lower.contains('fridge')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('tv') || lower.contains('television')) {
      return Icons.tv_rounded;
    } else if (lower.contains('iron') || lower.contains('heater')) {
      return Icons.local_fire_department_rounded;
    } else {
      return Icons.electrical_services_rounded;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.teal),
                  SizedBox(width: 8),
                  Text("Add Appliance"),
                ],
              ),
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
                      decoration: InputDecoration(
                        labelText: 'Preset Device',
                        prefixIcon: const Icon(Icons.devices),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Appliance Name',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: wattController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Power (Watts)',
                              suffixText: 'W',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Daily Usage Profile (Hours)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: offPeakController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Off-Peak Hrs',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: peakController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Peak Hrs',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  icon: const Icon(Icons.check),
                  label: const Text("Add Appliance"),
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBreakdownSheet() {
    final double energy = _billBreakdown['energyCharge'] ?? 0.0;
    final double fixed = _billBreakdown['fixedCharge'] ?? 0.0;
    final double fpa = _billBreakdown['fpaCharge'] ?? 0.0;
    final double qta = _billBreakdown['qtaCharge'] ?? 0.0;
    final double duty = _billBreakdown['electricityDuty'] ?? 0.0;
    final double gst = _billBreakdown['gst'] ?? 0.0;
    final double tvFee = _billBreakdown['tvFee'] ?? 0.0;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.teal, size: 28),
                  SizedBox(width: 8),
                  Text("Itemized Charges Breakdown",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              _buildRow("Energy Charge", energy),
              _buildRow("Fixed Charges", fixed),
              if (fpa > 0) _buildRow("Fuel Price Adjustment (FPA)", fpa),
              if (qta > 0) _buildRow("Quarterly Adjustment (QTA)", qta),
              _buildRow("Provincial Electricity Duty", duty),
              _buildRow("GST Tax (18%)", gst),
              _buildRow("TV Fee", tvFee),
              const Divider(height: 24),
              _buildRow("Estimated Total Bill", total, isBold: true, fontSize: 18),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String title, double value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("PKR ${value.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    final bool inDangerZone = _billBreakdown['isDangerZone'] ?? false;
    final bool isToU = _billBreakdown['isToU'] ?? false;
    final double total = _billBreakdown['estimatedTotal'] ?? 0.0;
    final double finalUnits = _billBreakdown['totalUnits'] ?? 0.0;

    // Progress percentage towards 200 units threshold
    final double progressVal = (finalUnits / 200.0).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('BillShield — Unit Predictor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Spinning Reset Refresh Button (360 degrees / 0.5s)
          RotationTransition(
            turns: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _resetSpinController,
                curve: Curves.easeInOutCubic,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Dashboard Values',
              onPressed: _resetDashboard,
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              widget.onThemeModeChanged?.call(newMode);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/logo2.jpg',
                height: 38,
                width: 38,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- HERO ESTIMATED BILL CARD WITH PROTECTION GAUGE ---
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: isDark ? const Color(0xFF0F2926) : const Color(0xFFE6F4F1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Badge Header Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: finalUnits == 0
                              ? Colors.grey.withOpacity(0.2)
                              : (inDangerZone
                                  ? Colors.amber.shade700
                                  : (_isProtected && finalUnits <= 200
                                      ? Colors.teal
                                      : Colors.red.shade700)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              finalUnits == 0
                                  ? Icons.power_off_rounded
                                  : (inDangerZone
                                      ? Icons.warning_amber_rounded
                                      : (_isProtected && finalUnits <= 200
                                          ? Icons.verified_user_rounded
                                          : Icons.gpp_bad_rounded)),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              finalUnits == 0
                                  ? "No Active Appliances"
                                  : (isToU
                                      ? "ToU Peak/Off-Peak Active"
                                      : (inDangerZone
                                          ? "DANGER ZONE: ${200 - finalUnits.round()} Units Left!"
                                          : (_isProtected && finalUnits <= 200
                                              ? "Protected Tariff Active"
                                              : "Unprotected Slab Category"))),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "ESTIMATED MONTHLY BILL",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.teal.shade200 : Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        "PKR ${total.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F766E),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Generated Usage: ${finalUnits.toStringAsFixed(1)} Units (kWh)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 200 Units Gauge Progress Bar
                      if (_isProtected && !isToU) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("0 Units", style: TextStyle(fontSize: 11)),
                            Text(
                              "${finalUnits.toStringAsFixed(0)} / 200 Units (Protected Limit)",
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 8,
                            backgroundColor: Colors.black12,
                            color: inDangerZone
                                ? Colors.amber.shade700
                                : (finalUnits > 200 ? Colors.red : Colors.teal),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text("View Itemized Tax Breakdown"),
                        onPressed: _showBreakdownSheet,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- PROVIDER SELECTION CARD ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedProvider,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Electricity Provider (DISCO)',
                          prefixIcon: const Icon(Icons.electric_bolt, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        ),
                        items: _providers.map((String provider) {
                          return DropdownMenuItem<String>(
                            value: provider,
                            child: Text(
                              provider,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: _onProviderChanged,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _peakHoursText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- APPLIANCE SIMULATOR CARD ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.devices_other_rounded, color: Colors.teal),
                              SizedBox(width: 8),
                              Text("Appliance Simulator",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add"),
                            onPressed: _showAddApplianceDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add home devices to estimate monthly unit consumption.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const Divider(height: 24),
                      if (_appliances.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.power_off_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text("No appliances added yet",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text("Tap '+ Add' to power on your devices",
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ..._appliances.asMap().entries.map((entry) {
                        int idx = entry.key;
                        ApplianceItem item = entry.value;
                        final icon = _getApplianceIcon(item.name);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade900.withOpacity(0.5)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: Colors.teal),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              "${item.wattage.toInt()}W  •  ${item.totalMonthlyUnits.toStringAsFixed(1)} Units/mo",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        _appliances.removeAt(idx);
                                      }
                                      _calculateBill();
                                    });
                                  },
                                ),
                                Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20, color: Colors.teal),
                                  onPressed: () {
                                    setState(() {
                                      item.quantity++;
                                      _calculateBill();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- ACCOUNT & TARIFF ADJUSTMENTS CARD ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formStateKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Colors.teal),
                            SizedBox(width: 8),
                            Text("Account Details & Adjustments",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Protected Consumer Category",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text("≤200 units/mo for last 6 consecutive months",
                              style: TextStyle(fontSize: 12)),
                          value: _isProtected,
                          activeColor: Colors.teal,
                          onChanged: (bool val) {
                            setState(() {
                              _isProtected = val;
                              _calculateBill();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sanctionedLoadController,
                          decoration: InputDecoration(
                            labelText: 'Sanctioned Load (kW)',
                            prefixIcon: const Icon(Icons.flash_on_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'Loads ≥ 5kW trigger ToU (Peak) billing.',
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _sanctionedLoad = double.tryParse(value ?? '') ?? 1.0,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blue.shade900.withOpacity(0.3)
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                                color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "FPA (Fuel Cost) & QTA (Maintenance) change monthly. Check your physical bill for exact monthly rates.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                                  ),
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
                                controller: _fpaController,
                                decoration: InputDecoration(
                                  labelText: 'FPA Rate (Fuel)',
                                  hintText: 'e.g. 2.5',
                                  border:
                                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _fpaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _qtaController,
                                decoration: InputDecoration(
                                  labelText: 'QTA Rate (Maint.)',
                                  hintText: 'e.g. 1.2',
                                  border:
                                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _qtaRate = double.tryParse(value ?? '') ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calculate_rounded),
                            label: const Text('Apply Tariffs & Calculate',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: () => _submitAdjustments(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
