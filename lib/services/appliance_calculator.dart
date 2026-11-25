import 'package:billshield/models/appliance_item.dart';

class HourReductionSuggestion {
  final ApplianceItem targetAppliance;
  final int applianceIndex;
  final double newDailyHours;
  final double savedKwh;
  final String title;
  final String description;

  const HourReductionSuggestion({
    required this.targetAppliance,
    required this.applianceIndex,
    required this.newDailyHours,
    required this.savedKwh,
    required this.title,
    required this.description,
  });
}

class ApplianceCalculator {
  static double calculateTotalMonthlyUnits(List<ApplianceItem> appliances) {
    return appliances.fold(0.0, (sum, item) => sum + item.monthlyUnits);
  }

  static double calculateTotalDailyUnits(List<ApplianceItem> appliances) {
    return appliances.fold(0.0, (sum, item) => sum + item.dailyUnits);
  }

  static Map<String, double> getUnitsByCategory(List<ApplianceItem> appliances) {
    final Map<String, double> categoryUnits = {
      'Cooling & HVAC': 0.0,
      'Refrigeration': 0.0,
      'Water & Heating': 0.0,
      'Lighting': 0.0,
      'Electronics': 0.0,
      'Other': 0.0,
    };

    for (final item in appliances) {
      final nameLower = item.name.toLowerCase();
      final units = item.monthlyUnits;

      if (nameLower.contains('ac') || nameLower.contains('fan') || nameLower.contains('cooler')) {
        categoryUnits['Cooling & HVAC'] = (categoryUnits['Cooling & HVAC'] ?? 0) + units;
      } else if (nameLower.contains('refrigerator') || nameLower.contains('fridge') || nameLower.contains('freezer')) {
        categoryUnits['Refrigeration'] = (categoryUnits['Refrigeration'] ?? 0) + units;
      } else if (nameLower.contains('pump') || nameLower.contains('geyser') || nameLower.contains('iron') || nameLower.contains('heater')) {
        categoryUnits['Water & Heating'] = (categoryUnits['Water & Heating'] ?? 0) + units;
      } else if (nameLower.contains('bulb') || nameLower.contains('light') || nameLower.contains('led')) {
        categoryUnits['Lighting'] = (categoryUnits['Lighting'] ?? 0) + units;
      } else if (nameLower.contains('tv') || nameLower.contains('computer') || nameLower.contains('laptop') || nameLower.contains('router')) {
        categoryUnits['Electronics'] = (categoryUnits['Electronics'] ?? 0) + units;
      } else {
        categoryUnits['Other'] = (categoryUnits['Other'] ?? 0) + units;
      }
    }

    return categoryUnits;
  }

  static HourReductionSuggestion? getTopActionableSuggestion(
    List<ApplianceItem> appliances,
    double totalUnits,
  ) {
    if (appliances.isEmpty) return null;

    // Find top energy consuming appliance that has dailyHours > 0.5
    int topIndex = -1;
    double maxUnits = -1.0;

    for (int i = 0; i < appliances.length; i++) {
      final item = appliances[i];
      if (item.dailyHours > 0.5 && item.monthlyUnits > maxUnits) {
        maxUnits = item.monthlyUnits;
        topIndex = i;
      }
    }

    if (topIndex == -1) return null;

    final topItem = appliances[topIndex];
    final excess = totalUnits > 200.0 ? totalUnits - 200.0 : 0.0;

    // Calculate how many hours of reduction are needed for this appliance to cut excess (or reduce by ~1.5 to 2.5 hrs)
    final kwhPerDailyHour = (topItem.watts * topItem.quantity * 30.0) / 1000.0;
    if (kwhPerDailyHour <= 0) return null;

    double neededHourReduction = (excess / kwhPerDailyHour).clamp(0.5, 4.0);
    double newHours = (topItem.dailyHours - neededHourReduction).clamp(0.5, 23.5);
    newHours = (newHours * 2).roundToDouble() / 2.0; // Round to nearest 0.5 hr

    final actualReducedHours = topItem.dailyHours - newHours;
    if (actualReducedHours <= 0) return null;

    final savedKwh = actualReducedHours * kwhPerDailyHour;

    return HourReductionSuggestion(
      targetAppliance: topItem,
      applianceIndex: topIndex,
      newDailyHours: newHours,
      savedKwh: savedKwh,
      title: 'Reduce ${topItem.name} Operating Time',
      description:
          'Cut ${topItem.name} usage from ${topItem.dailyHours.toStringAsFixed(1)}h to ${newHours.toStringAsFixed(1)}h/day to save ~${savedKwh.toStringAsFixed(1)} kWh/mo.',
    );
  }

  static List<String> generateEnergyTips(List<ApplianceItem> appliances, bool isProtected) {
    final tips = <String>[];

    final hasAc = appliances.any((a) => a.name.toLowerCase().contains('ac'));
    if (hasAc) {
      tips.add('Set your AC temperature to 26°C instead of 18°C–22°C to save up to 25% on cooling power.');
    }

    final peakAppliances = appliances.where((a) => a.isPeakHours && a.watts >= 500);
    if (peakAppliances.isNotEmpty) {
      tips.add('Shift heavy appliances (AC, Iron, Water Pump) away from Peak Hours (6 PM - 10 PM) to avoid higher Peak Tariffs.');
    }

    final totalUnits = calculateTotalMonthlyUnits(appliances);
    if (!isProtected && totalUnits > 200 && totalUnits <= 250) {
      final excess = totalUnits - 200;
      tips.add('You are only ${excess.toStringAsFixed(1)} kWh over the 200-unit Protected limit! Reducing daily fan or AC usage by 1 hour can drop your bill significantly.');
    } else if (isProtected && totalUnits >= 160) {
      final remaining = 200 - totalUnits;
      tips.add('Warning: You are approaching the 200-unit limit with ${remaining.toStringAsFixed(1)} units left. Keep total usage below 200 units to retain Protected slab rates.');
    }

    if (tips.isEmpty) {
      tips.add('Regularly check appliance energy tags and switch older bulbs to energy-efficient LEDs.');
    }

    return tips;
  }
}
