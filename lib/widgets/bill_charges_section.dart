import 'package:flutter/material.dart';

class BillChargesSection extends StatefulWidget {
  final double fpaRate;
  final double qtaRate;
  final double fixedCharges;
  final bool includeMeterRent;
  final bool includeTvFee;
  final bool isThreePhase;
  final bool is6MonthLocked;
  final Function({
    required double fpaRate,
    required double qtaRate,
    required double fixedCharges,
    required bool includeMeterRent,
    required bool includeTvFee,
    required bool isThreePhase,
    required bool is6MonthLocked,
  }) onApplyChanges;

  const BillChargesSection({
    super.key,
    required this.fpaRate,
    required this.qtaRate,
    required this.fixedCharges,
    required this.includeMeterRent,
    required this.includeTvFee,
    this.isThreePhase = false,
    this.is6MonthLocked = false,
    required this.onApplyChanges,
  });

  @override
  State<BillChargesSection> createState() => _BillChargesSectionState();
}

class _BillChargesSectionState extends State<BillChargesSection> {
  late final TextEditingController _fpaController;
  late final TextEditingController _qtaController;
  late final TextEditingController _fixedController;
  late bool _includeMeterRent;
  late bool _includeTvFee;
  late bool _isThreePhase;
  late bool _is6MonthLocked;

  @override
  void initState() {
    super.initState();
    _fpaController =
        TextEditingController(text: widget.fpaRate.toStringAsFixed(2));
    _qtaController =
        TextEditingController(text: widget.qtaRate.toStringAsFixed(2));
    _fixedController =
        TextEditingController(text: widget.fixedCharges.toStringAsFixed(2));
    _includeMeterRent = widget.includeMeterRent;
    _includeTvFee = widget.includeTvFee;
    _isThreePhase = widget.isThreePhase;
    _is6MonthLocked = widget.is6MonthLocked;
  }

  @override
  void didUpdateWidget(covariant BillChargesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fpaRate != widget.fpaRate) {
      _fpaController.text = widget.fpaRate.toStringAsFixed(2);
    }
    if (oldWidget.qtaRate != widget.qtaRate) {
      _qtaController.text = widget.qtaRate.toStringAsFixed(2);
    }
    if (oldWidget.fixedCharges != widget.fixedCharges) {
      _fixedController.text = widget.fixedCharges.toStringAsFixed(2);
    }
    _includeMeterRent = widget.includeMeterRent;
    _includeTvFee = widget.includeTvFee;
    _isThreePhase = widget.isThreePhase;
    _is6MonthLocked = widget.is6MonthLocked;
  }

  @override
  void dispose() {
    _fpaController.dispose();
    _qtaController.dispose();
    _fixedController.dispose();
    super.dispose();
  }

  void _apply() {
    final parsedFpa = double.tryParse(_fpaController.text.trim()) ?? widget.fpaRate;
    final parsedQta = double.tryParse(_qtaController.text.trim()) ?? widget.qtaRate;
    final parsedFixed = double.tryParse(_fixedController.text.trim()) ?? widget.fixedCharges;

    widget.onApplyChanges(
      fpaRate: parsedFpa >= 0 ? parsedFpa : widget.fpaRate,
      qtaRate: parsedQta >= 0 ? parsedQta : widget.qtaRate,
      fixedCharges: parsedFixed >= 0 ? parsedFixed : widget.fixedCharges,
      includeMeterRent: _includeMeterRent,
      includeTvFee: _includeTvFee,
      isThreePhase: _isThreePhase,
      is6MonthLocked: _is6MonthLocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.tune,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'FPA, QTA & Meter Controls',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'FPA: Rs. ${widget.fpaRate.toStringAsFixed(2)}/u • QTA: Rs. ${widget.qtaRate.toStringAsFixed(2)}/u • '
          '${widget.isThreePhase ? "3-Phase (Rs 100)" : "1-Phase (Rs 50)"}',
          style: const TextStyle(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fpaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'FPA (Rs./u)',
                    hintText: '2.50',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _qtaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'QTA (Rs./u)',
                    hintText: '1.75',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fixedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fixed (Rs.)',
                    hintText: '0.00',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_isThreePhase ? 'Meter Rent (Rs 100)' : 'Meter Rent (Rs 50)'),
                  value: _includeMeterRent,
                  onChanged: (val) {
                    setState(() => _includeMeterRent = val ?? true);
                    _apply();
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('PTV Fee (Rs. 35)'),
                  value: _includeTvFee,
                  onChanged: (val) {
                    setState(() => _includeTvFee = val ?? false);
                    _apply();
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Three-Phase Meter Connection'),
            subtitle: const Text(
              'Applies 3-phase commercial/residential rules and higher meter rent (Rs. 100)',
              style: TextStyle(fontSize: 11),
            ),
            value: _isThreePhase,
            onChanged: (val) {
              setState(() => _isThreePhase = val);
              _apply();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('6-Month Unprotected Lock (>200u recently)'),
            subtitle: const Text(
              'NEPRA Rule: Exceeding 200 kWh in any of the last 6 months locks tariff as Unprotected',
              style: TextStyle(fontSize: 11),
            ),
            value: _is6MonthLocked,
            onChanged: (val) {
              setState(() => _is6MonthLocked = val);
              _apply();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Update Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
