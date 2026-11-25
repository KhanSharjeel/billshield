class UpsBattery {
  final int batteryVoltage;
  final double capacityAh;
  final String batteryType;
  final double inverterEfficiency;

  const UpsBattery({
    this.batteryVoltage = 12,
    this.capacityAh = 200.0,
    this.batteryType = 'Tubular Lead-Acid',
    this.inverterEfficiency = 0.85,
  });

  double get depthOfDischarge =>
      batteryType.toLowerCase().contains('lithium') ? 0.90 : 0.65;

  double get totalCapacityWh => capacityAh * batteryVoltage;

  double get usableCapacityWh =>
      totalCapacityWh * depthOfDischarge * inverterEfficiency;

  double calculateBackupHours(double activeLoadWatts) {
    if (activeLoadWatts <= 0) return 0.0;
    return usableCapacityWh / activeLoadWatts;
  }

  double calculateRechargeKwh() {
    // Energy needed from grid to fully recharge (accounting for battery charging efficiency ~85%)
    return (totalCapacityWh * depthOfDischarge / 0.85) / 1000.0;
  }

  UpsBattery copyWith({
    int? batteryVoltage,
    double? capacityAh,
    String? batteryType,
    double? inverterEfficiency,
  }) {
    return UpsBattery(
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      capacityAh: capacityAh ?? this.capacityAh,
      batteryType: batteryType ?? this.batteryType,
      inverterEfficiency: inverterEfficiency ?? this.inverterEfficiency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'batteryVoltage': batteryVoltage,
      'capacityAh': capacityAh,
      'batteryType': batteryType,
      'inverterEfficiency': inverterEfficiency,
    };
  }

  factory UpsBattery.fromMap(Map<dynamic, dynamic> map) {
    return UpsBattery(
      batteryVoltage: (map['batteryVoltage'] as num?)?.toInt() ?? 12,
      capacityAh: (map['capacityAh'] as num?)?.toDouble() ?? 200.0,
      batteryType: map['batteryType'] as String? ?? 'Tubular Lead-Acid',
      inverterEfficiency:
          (map['inverterEfficiency'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
