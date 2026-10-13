import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nepra_engine.dart';

void main() {
  runApp(const BillShieldApp());
}

class BillShieldApp extends StatelessWidget {
  const BillShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillShield',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Teal primary
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const BillShieldHomeScreen(),
    );
  }
}

class BillShieldHomeScreen extends StatefulWidget {
  const BillShieldHomeScreen({super.key});

  @override
  State<BillShieldHomeScreen> createState() => _BillShieldHomeScreenState();
}

class _BillShieldHomeScreenState extends State<BillShieldHomeScreen> {
  int _consumedUnits = 185;
  bool _isProtected = true;
  double _sanctionedLoadKw = 1.0;
  double _fpaRate = 0.0;
  double _qtaRate = 0.0;

  late final TextEditingController _unitsController;
  late final TextEditingController _loadController;
  late final TextEditingController _fpaController;
  late final TextEditingController _qtaController;

  @override
  void initState() {
    super.initState();
    _unitsController = TextEditingController(text: _consumedUnits.toString());
    _loadController = TextEditingController(text: _sanctionedLoadKw.toStringAsFixed(1));
    _fpaController = TextEditingController(text: _fpaRate.toString());
    _qtaController = TextEditingController(text: _qtaRate.toString());
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _loadController.dispose();
    _fpaController.dispose();
    _qtaController.dispose();
    super.dispose();
  }

  void _updateUnits(int newUnits) {
    final clamped = newUnits.clamp(0, 2000);
    setState(() {
      _consumedUnits = clamped;
      _unitsController.text = clamped.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bill = NepraEngine.calculateMonthlyBill(
      consumedUnits: _consumedUnits,
      isProtected: _isProtected,
      sanctionedLoadKw: _sanctionedLoadKw,
      fpaRate: _fpaRate,
      qtaRate: _qtaRate,
    );

    final bool isDangerZone = bill['isDangerZone'] as bool;
    final double totalBill = bill['estimatedTotal'] as double;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text(
              'BillShield',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () {
              setState(() {
                _consumedUnits = 185;
                _isProtected = true;
                _sanctionedLoadKw = 1.0;
                _fpaRate = 0.0;
                _qtaRate = 0.0;
                _unitsController.text = '185';
                _loadController.text = '1.0';
                _fpaController.text = '0.0';
                _qtaController.text = '0.0';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About NEPRA Tariff Rules',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shield Status Banner
              _buildShieldBanner(context, isDangerZone),

              const SizedBox(height: 16),

              // Total Estimate Hero Card
              _buildTotalHeroCard(context, totalBill),

              const SizedBox(height: 16),

              // Inputs Card
              _buildInputsCard(context),

              const SizedBox(height: 16),

              // Detailed Itemized Breakdown Card
              _buildBreakdownCard(context, bill),

              const SizedBox(height: 16),

              // Quick Tips
              _buildTipsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShieldBanner(BuildContext context, bool isDangerZone) {
    if (_isProtected && isDangerZone) {
      final remainingUnits = 200 - _consumedUnits;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 36, color: Colors.amber.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Danger Zone: $remainingUnits Unit${remainingUnits == 1 ? '' : 's'} Remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay at or under 200 units to keep your Protected consumer status and lower tariff rates!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_isProtected && _consumedUnits > 200) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade700, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.gpp_bad_rounded, size: 36, color: Colors.red.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ Protected Limit Exceeded!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exceeding 200 units forfeits Protected Status for 6 months, shifting calculation to higher Unprotected tariff slabs.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_isProtected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_rounded, size: 36, color: Color(0xFF0D9488)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🛡️ Protected Category Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You are safe within the 200-unit threshold. Keep energy usage under 200 units.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.shade300, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 36, color: Colors.blueGrey),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unprotected Category Tariff',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Standard flat telescopic/highest slab rates applied based on total monthly consumption.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTotalHeroCard(BuildContext context, double totalBill) {
    final theme = Theme.of(context);
    final avgCostPerUnit = _consumedUnits > 0 ? (totalBill / _consumedUnits) : 0.0;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'ESTIMATED MONTHLY BILL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. ${totalBill.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Avg. Effective Rate: Rs. ${avgCostPerUnit.toStringAsFixed(2)} / unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage & Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Units Consumed Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Consumed Units (kWh):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      setState(() {
                        _consumedUnits = parsed;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Unit Slider
            Slider(
              value: _consumedUnits.toDouble().clamp(0.0, 1000.0),
              min: 0,
              max: 1000,
              divisions: 200,
              label: '$_consumedUnits units',
              onChanged: (val) => _updateUnits(val.round()),
            ),

            // Quick increment chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('-50'),
                  onPressed: () => _updateUnits(_consumedUnits - 50),
                ),
                ActionChip(
                  label: const Text('-10'),
                  onPressed: () => _updateUnits(_consumedUnits - 10),
                ),
                ActionChip(
                  label: const Text('+10'),
                  onPressed: () => _updateUnits(_consumedUnits + 10),
                ),
                ActionChip(
                  label: const Text('+50'),
                  onPressed: () => _updateUnits(_consumedUnits + 50),
                ),
                ActionChip(
                  label: const Text('200 Max Protected'),
                  avatar: const Icon(Icons.shield, size: 16),
                  onPressed: () => _updateUnits(200),
                ),
              ],
            ),

            const Divider(height: 32),

            // Protected Consumer Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Protected Consumer Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Has your consumption been ≤200 units for the last 6 consecutive months?',
                style: TextStyle(fontSize: 12),
              ),
              value: _isProtected,
              onChanged: (bool value) {
                setState(() {
                  _isProtected = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Sanctioned Load
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sanctioned Load (kW):',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Used to calculate fixed charges for unprotected meters',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _loadController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 'kW',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 1.0;
                      setState(() {
                        _sanctionedLoadKw = parsed;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Accordion for FPA / QTA Rates
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Fuel & Quarterly Adjustments (FPA & QTA)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Optional monthly fuel price & quarterly tariff adjustments',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fpaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'FPA Rate (Rs/unit)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _fpaRate = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _qtaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'QTA Rate (Rs/unit)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _qtaRate = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(BuildContext context, Map<String, dynamic> bill) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Bill Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildRow('Energy Charges', bill['energyCharge'] as double),
            _buildRow('Fixed Charges', bill['fixedCharge'] as double),
            if ((bill['fpaCharge'] as double) > 0)
              _buildRow('Fuel Price Adjustment (FPA)', bill['fpaCharge'] as double),
            if ((bill['qtaCharge'] as double) > 0)
              _buildRow('Quarterly Tariff Adjustment (QTA)', bill['qtaCharge'] as double),

            const Divider(height: 24),
            const Text(
              'Government Taxes & Fees',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            _buildRow('Electricity Duty (1.5%)', bill['electricityDuty'] as double),
            _buildRow('GST (18%)', bill['gst'] as double),
            _buildRow('TV Fee', bill['tvFee'] as double),

            const Divider(height: 24),

            _buildRow(
              'Total Estimated Bill',
              bill['estimatedTotal'] as double,
              isBold: true,
              fontSize: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double amount, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: const Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'BillShield Saver Tips',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '• The 200 Unit Cliff: Exceeding 200 units even by 1 unit triggers non-protected rates for 6 future months.\n'
              '• Monitor meter readings mid-month to regulate high-draw appliances like ACs and electric heaters.\n'
              '• Fixed charges scale with your Sanctioned Load (kW) for unprotected consumers.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BillShield',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.shield, size: 48, color: Color(0xFF0D9488)),
      children: [
        const SizedBox(height: 12),
        const Text(
          'BillShield helps users estimate NEPRA electricity tariffs in Pakistan, with active shielding alerts to prevent falling into higher unprotected tariff slabs.',
        ),
      ],
    );
  }
}
