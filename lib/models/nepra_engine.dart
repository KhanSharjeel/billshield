class NepraEngine {
  static const double gstRate = 0.18;
  static const double tvFee = 35.0;

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

    // If no appliances have been added, return zeroes across the board
    if (totalUnits == 0) {
      return {
        'totalUnits': 0.0,
        'energyCharge': 0.0,
        'fixedCharge': 0.0,
        'fpaCharge': 0.0,
        'qtaCharge': 0.0,
        'electricityDuty': 0.0,
        'gst': 0.0,
        'tvFee': 0.0,
        'estimatedTotal': 0.0,
        'isDangerZone': false,
        'isToU': false,
      };
    }

    double energyCharge = 0.0;
    double fixedCharge = 0.0;

    // Provincial Electricity Duty logic based on Provider
    double electricityDutyRate = 0.015; // Default 1.5%
    if (provider.contains('LESCO') ||
        provider.contains('IESCO') ||
        provider.contains('MEPCO') ||
        provider.contains('FESCO') ||
        provider.contains('GEPCO')) {
      electricityDutyRate = 0.02; // Punjab ~2.0%
    } else if (provider.contains('K-Electric') || provider.contains('HESCO')) {
      electricityDutyRate = 0.015; // Sindh ~1.5%
    } else if (provider.contains('PESCO')) {
      electricityDutyRate = 0.015; // KPK ~1.5%
    } else if (provider.contains('QESCO')) {
      electricityDutyRate = 0.01; // Balochistan ~1.0%
    }

    // NEPRA Time of Use (ToU) Rule: >= 5kW load uses separate Peak/Off-Peak rates
    bool isToU = sanctionedLoadKw >= 5.0;

    if (isToU) {
      // ToU Rates
      energyCharge = (peakUnits * 50.0) + (offPeakUnits * 35.0);
      fixedCharge = 500.0 * sanctionedLoadKw;
    } else {
      // Standard Slab Logic
      if (isProtected && totalUnits <= 200) {
        if (totalUnits <= 100) {
          energyCharge = totalUnits * 10.54;
          fixedCharge = 200.0;
        } else {
          energyCharge = (100 * 10.54) + ((totalUnits - 100) * 13.01);
          fixedCharge = 300.0;
        }
      } else {
        if (totalUnits <= 100) {
          energyCharge = totalUnits * 22.44;
          fixedCharge = 275.0 * sanctionedLoadKw;
        } else if (totalUnits <= 200) {
          energyCharge = totalUnits * 28.91;
          fixedCharge = 300.0 * sanctionedLoadKw;
        } else if (totalUnits <= 300) {
          energyCharge = totalUnits * 33.10;
          fixedCharge = 350.0 * sanctionedLoadKw;
        } else if (totalUnits <= 400) {
          energyCharge = totalUnits * 36.46;
          fixedCharge = 400.0 * sanctionedLoadKw;
        } else {
          energyCharge = totalUnits * 40.22;
          fixedCharge = 675.0 * sanctionedLoadKw;
        }
      }
    }

    double fpaCharge = totalUnits * fpaRate;
    double qtaCharge = totalUnits * qtaRate;
    double totalChargesBeforeTaxes = energyCharge + fixedCharge + fpaCharge + qtaCharge;

    double electricityDuty = totalChargesBeforeTaxes * electricityDutyRate;
    double gst = (totalChargesBeforeTaxes + electricityDuty) * gstRate;

    double estimatedTotal = totalChargesBeforeTaxes + electricityDuty + gst + tvFee;

    return {
      'totalUnits': totalUnits,
      'energyCharge': energyCharge,
      'fixedCharge': fixedCharge,
      'fpaCharge': fpaCharge,
      'qtaCharge': qtaCharge,
      'electricityDuty': electricityDuty,
      'gst': gst,
      'tvFee': tvFee,
      'estimatedTotal': estimatedTotal,
      'isDangerZone': isProtected && totalUnits >= 180 && totalUnits <= 200,
      'isToU': isToU,
    };
  }
}