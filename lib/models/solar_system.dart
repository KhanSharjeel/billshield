class SolarSystem {
  final double systemCapacityKw;
  final double dailyPeakSunHours;
  final double exportBuybackRate;
  final double systemCostPkr;

  const SolarSystem({
    required this.systemCapacityKw,
    this.dailyPeakSunHours = 5.0,
    this.exportBuybackRate = 22.00,
    this.systemCostPkr = 850000.0,
  });

  double get dailyGenerationKwh => systemCapacityKw * dailyPeakSunHours;
  double get monthlyGenerationKwh => dailyGenerationKwh * 30.0;
  double get monthlyExportValuePkr => monthlyGenerationKwh * exportBuybackRate;

  SolarSystem copyWith({
    double? systemCapacityKw,
    double? dailyPeakSunHours,
    double? exportBuybackRate,
    double? systemCostPkr,
  }) {
    return SolarSystem(
      systemCapacityKw: systemCapacityKw ?? this.systemCapacityKw,
      dailyPeakSunHours: dailyPeakSunHours ?? this.dailyPeakSunHours,
      exportBuybackRate: exportBuybackRate ?? this.exportBuybackRate,
      systemCostPkr: systemCostPkr ?? this.systemCostPkr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'systemCapacityKw': systemCapacityKw,
      'dailyPeakSunHours': dailyPeakSunHours,
      'exportBuybackRate': exportBuybackRate,
      'systemCostPkr': systemCostPkr,
    };
  }

  factory SolarSystem.fromMap(Map<dynamic, dynamic> map) {
    return SolarSystem(
      systemCapacityKw: (map['systemCapacityKw'] as num?)?.toDouble() ?? 5.0,
      dailyPeakSunHours: (map['dailyPeakSunHours'] as num?)?.toDouble() ?? 5.0,
      exportBuybackRate: (map['exportBuybackRate'] as num?)?.toDouble() ?? 22.0,
      systemCostPkr: (map['systemCostPkr'] as num?)?.toDouble() ?? 850000.0,
    );
  }
}
