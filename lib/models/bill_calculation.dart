class BillCalculation {
  final int? id;
  final String provider;
  final double totalUnits;
  final double peakUnits;
  final double offPeakUnits;
  final bool isProtected;
  final bool is6MonthUnprotectedLocked;
  final bool isThreePhase;
  final double excessUnitsOverProtected;
  final double estimatedSavingsIfProtected;
  final double baseEnergyCharge;
  final double fpaCharge;
  final double qtaCharge;
  final double fixedCharges;
  final double meterRent;
  final double tvFee;
  final double electricityDuty;
  final double gstAndDuties;
  final double totalBill;
  final DateTime timestamp;

  const BillCalculation({
    this.id,
    required this.provider,
    required this.totalUnits,
    required this.peakUnits,
    required this.offPeakUnits,
    required this.isProtected,
    this.is6MonthUnprotectedLocked = false,
    this.isThreePhase = false,
    required this.excessUnitsOverProtected,
    required this.estimatedSavingsIfProtected,
    required this.baseEnergyCharge,
    required this.fpaCharge,
    required this.qtaCharge,
    required this.fixedCharges,
    required this.meterRent,
    this.tvFee = 35.0,
    this.electricityDuty = 0.0,
    required this.gstAndDuties,
    required this.totalBill,
    required this.timestamp,
  });

  bool get isWarning => isProtected && totalUnits > 150.0 && totalUnits <= 200.0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'provider': provider,
      'totalUnits': totalUnits,
      'peakUnits': peakUnits,
      'offPeakUnits': offPeakUnits,
      'isProtected': isProtected,
      'is6MonthUnprotectedLocked': is6MonthUnprotectedLocked,
      'isThreePhase': isThreePhase,
      'excessUnitsOverProtected': excessUnitsOverProtected,
      'estimatedSavingsIfProtected': estimatedSavingsIfProtected,
      'baseEnergyCharge': baseEnergyCharge,
      'fpaCharge': fpaCharge,
      'qtaCharge': qtaCharge,
      'fixedCharges': fixedCharges,
      'meterRent': meterRent,
      'tvFee': tvFee,
      'electricityDuty': electricityDuty,
      'gstAndDuties': gstAndDuties,
      'totalBill': totalBill,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BillCalculation.fromMap(Map<dynamic, dynamic> map) {
    return BillCalculation(
      id: map['id'] as int?,
      provider: map['provider'] as String? ?? 'IESCO',
      totalUnits: (map['totalUnits'] as num?)?.toDouble() ?? 0.0,
      peakUnits: (map['peakUnits'] as num?)?.toDouble() ?? 0.0,
      offPeakUnits: (map['offPeakUnits'] as num?)?.toDouble() ?? 0.0,
      isProtected: map['isProtected'] as bool? ?? true,
      is6MonthUnprotectedLocked:
          map['is6MonthUnprotectedLocked'] as bool? ?? false,
      isThreePhase: map['isThreePhase'] as bool? ?? false,
      excessUnitsOverProtected:
          (map['excessUnitsOverProtected'] as num?)?.toDouble() ?? 0.0,
      estimatedSavingsIfProtected:
          (map['estimatedSavingsIfProtected'] as num?)?.toDouble() ?? 0.0,
      baseEnergyCharge: (map['baseEnergyCharge'] as num?)?.toDouble() ?? 0.0,
      fpaCharge: (map['fpaCharge'] as num?)?.toDouble() ?? 0.0,
      qtaCharge: (map['qtaCharge'] as num?)?.toDouble() ?? 0.0,
      fixedCharges: (map['fixedCharges'] as num?)?.toDouble() ?? 0.0,
      meterRent: (map['meterRent'] as num?)?.toDouble() ?? 0.0,
      tvFee: (map['tvFee'] as num?)?.toDouble() ?? 35.0,
      electricityDuty: (map['electricityDuty'] as num?)?.toDouble() ?? 0.0,
      gstAndDuties: (map['gstAndDuties'] as num?)?.toDouble() ?? 0.0,
      totalBill: (map['totalBill'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
