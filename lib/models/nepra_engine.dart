class NepraEngine {
  static const double gstRate = 0.18;
  static const double tvFee = 35.0;
  static const double electricityDutyRate = 0.015;

  static Map<String, dynamic> calculateMonthlyBill({
    required int consumedUnits,
    required bool isProtected,
    required double sanctionedLoadKw,
    double fpaRate = 0.0,
    double qtaRate = 0.0,
  }) {
    double energyCharge = 0.0;
    double fixedCharge = 0.0;

    if (isProtected && consumedUnits <= 200) {
      if (consumedUnits <= 100) {
        energyCharge = consumedUnits * 10.54;
        fixedCharge = 200.0;
      } else {
        energyCharge = (100 * 10.54) + ((consumedUnits - 100) * 13.01);
        fixedCharge = 300.0;
      }
    } else {
      if (consumedUnits <= 100) {
        energyCharge = consumedUnits * 22.44;
        fixedCharge = 275.0 * sanctionedLoadKw;
      } else if (consumedUnits <= 200) {
        energyCharge = consumedUnits * 28.91;
        fixedCharge = 300.0 * sanctionedLoadKw;
      } else if (consumedUnits <= 300) {
        energyCharge = consumedUnits * 33.10;
        fixedCharge = 350.0 * sanctionedLoadKw;
      } else if (consumedUnits <= 400) {
        energyCharge = consumedUnits * 36.46;
        fixedCharge = 400.0 * sanctionedLoadKw;
      } else {
        energyCharge = consumedUnits * 40.22;
        fixedCharge = 675.0 * sanctionedLoadKw;
      }
    }

    double fpaCharge = consumedUnits * fpaRate;
    double qtaCharge = consumedUnits * qtaRate;
    double totalChargesBeforeTaxes = energyCharge + fixedCharge + fpaCharge + qtaCharge;

    double electricityDuty = totalChargesBeforeTaxes * electricityDutyRate;
    double gst = (totalChargesBeforeTaxes + electricityDuty) * gstRate;

    double estimatedTotal = totalChargesBeforeTaxes + electricityDuty + gst + tvFee;

    return {
      'energyCharge': energyCharge,
      'fixedCharge': fixedCharge,
      'fpaCharge': fpaCharge,
      'qtaCharge': qtaCharge,
      'electricityDuty': electricityDuty,
      'gst': gst,
      'tvFee': tvFee,
      'estimatedTotal': estimatedTotal,
      'isDangerZone': isProtected && consumedUnits >= 180 && consumedUnits <= 200,
    };
  }
}