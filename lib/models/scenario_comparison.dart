class ScenarioComparison {
  final String scenarioNameA;
  final String scenarioNameB;
  final double unitsA;
  final double unitsB;
  final double billA;
  final double billB;
  final double investmentCostPkr;

  const ScenarioComparison({
    required this.scenarioNameA,
    required this.scenarioNameB,
    required this.unitsA,
    required this.unitsB,
    required this.billA,
    required this.billB,
    this.investmentCostPkr = 0.0,
  });

  double get monthlySavingsPkr => billA - billB;
  double get annualSavingsPkr => monthlySavingsPkr * 12.0;
  double get monthlyUnitSavings => unitsA - unitsB;

  double get paybackMonths {
    if (monthlySavingsPkr <= 0 || investmentCostPkr <= 0) return 0.0;
    return investmentCostPkr / monthlySavingsPkr;
  }

  double get paybackYears => paybackMonths / 12.0;

  Map<String, dynamic> toMap() {
    return {
      'scenarioNameA': scenarioNameA,
      'scenarioNameB': scenarioNameB,
      'unitsA': unitsA,
      'unitsB': unitsB,
      'billA': billA,
      'billB': billB,
      'investmentCostPkr': investmentCostPkr,
    };
  }

  factory ScenarioComparison.fromMap(Map<dynamic, dynamic> map) {
    return ScenarioComparison(
      scenarioNameA: map['scenarioNameA'] as String? ?? 'Scenario A',
      scenarioNameB: map['scenarioNameB'] as String? ?? 'Scenario B',
      unitsA: (map['unitsA'] as num?)?.toDouble() ?? 0.0,
      unitsB: (map['unitsB'] as num?)?.toDouble() ?? 0.0,
      billA: (map['billA'] as num?)?.toDouble() ?? 0.0,
      billB: (map['billB'] as num?)?.toDouble() ?? 0.0,
      investmentCostPkr: (map['investmentCostPkr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
