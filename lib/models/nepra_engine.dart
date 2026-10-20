class NepraEngine {
  static const double gstRate = 0.18; // 18%

  static Map<String, dynamic> calculateMonthlyBill({
    required double offPeakUnits,
    required double peakUnits,
    required bool isProtected,
    required double sanctionedLoadKw,
    required String provider,
    double fpaRate = 0.0,
    double qtaRate = 0.0,
  }) {
    double totalUnits = offPeakUnits + peakUnits;

    if (totalUnits == 0) {
      return {
        'totalUnits': 0.0,
        'energyCharge': 0.0,
        'fixedCharge': 0.0,
        'fpaCharge': 0.0,
        'qtaCharge': 0.0,
        'electricityDuty': 0.0,
        'gst': 0.0,
        'estimatedTotal': 0.0,
        'isDangerZone': false,
        'isToU': false,
      };
    }

    bool isToU = sanctionedLoadKw >= 5.0;
    bool isDangerZone = !isToU && isProtected && totalUnits >= 180 && totalUnits <= 200;

    double energyCharge = 0.0;

    if (isToU) {
      double offPeakRate = 35.0;
      double peakRate = 50.0;
      energyCharge = (offPeakUnits * offPeakRate) + (peakUnits * peakRate);
    } else {
      double baseRate = isProtected ? 15.0 : 35.0;
      energyCharge = totalUnits * baseRate;
    }

    double fixedCharge = (isProtected || isToU) ? 0.0 : (sanctionedLoadKw * 500.0);
    double fpaCharge = totalUnits * fpaRate;
    double qtaCharge = totalUnits * qtaRate;

    double electricityDuty = energyCharge * 0.015; // 1.5%
    double taxableAmount = energyCharge + fixedCharge + fpaCharge + qtaCharge + electricityDuty;
    double gst = taxableAmount * gstRate;

    // The TV Fee has been completely removed from the grand total
    double estimatedTotal = taxableAmount + gst;

    return {
      'totalUnits': totalUnits,
      'energyCharge': energyCharge,
      'fixedCharge': fixedCharge,
      'fpaCharge': fpaCharge,
      'qtaCharge': qtaCharge,
      'electricityDuty': electricityDuty,
      'gst': gst,
      'estimatedTotal': estimatedTotal,
      'isDangerZone': isDangerZone,
      'isToU': isToU,
    };
  }
}