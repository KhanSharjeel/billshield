class BillCalculation {
  final String provider;
  final double totalUnits;
  final double peakUnits;
  final double offPeakUnits;
  final bool isProtected;
  final double baseEnergyCharge;
  final double fpaCharge;
  final double qtaCharge;
  final double gstAndDuties;
  final double totalBill;
  final DateTime timestamp;

  const BillCalculation({
    required this.provider,
    required this.totalUnits,
    required this.peakUnits,
    required this.offPeakUnits,
    required this.isProtected,
    required this.baseEnergyCharge,
    required this.fpaCharge,
    required this.qtaCharge,
    required this.gstAndDuties,
    required this.totalBill,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'totalUnits': totalUnits,
      'peakUnits': peakUnits,
      'offPeakUnits': offPeakUnits,
      'isProtected': isProtected,
      'baseEnergyCharge': baseEnergyCharge,
      'fpaCharge': fpaCharge,
      'qtaCharge': qtaCharge,
      'gstAndDuties': gstAndDuties,
      'totalBill': totalBill,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BillCalculation.fromMap(Map<dynamic, dynamic> map) {
    return BillCalculation(
      provider: map['provider'] as String? ?? 'IESCO',
      totalUnits: (map['totalUnits'] as num?)?.toDouble() ?? 0.0,
      peakUnits: (map['peakUnits'] as num?)?.toDouble() ?? 0.0,
      offPeakUnits: (map['offPeakUnits'] as num?)?.toDouble() ?? 0.0,
      isProtected: map['isProtected'] as bool? ?? true,
      baseEnergyCharge: (map['baseEnergyCharge'] as num?)?.toDouble() ?? 0.0,
      fpaCharge: (map['fpaCharge'] as num?)?.toDouble() ?? 0.0,
      qtaCharge: (map['qtaCharge'] as num?)?.toDouble() ?? 0.0,
      gstAndDuties: (map['gstAndDuties'] as num?)?.toDouble() ?? 0.0,
      totalBill: (map['totalBill'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}