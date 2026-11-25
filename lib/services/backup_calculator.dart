import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/ups_battery.dart';

class BackupResult {
  final double activeLoadWatts;
  final double backupHours;
  final double rechargeKwhPerOutage;
  final double monthlyRechargeKwh;

  const BackupResult({
    required this.activeLoadWatts,
    required this.backupHours,
    required this.rechargeKwhPerOutage,
    required this.monthlyRechargeKwh,
  });
}

class BackupCalculator {
  static BackupResult calculateBackup({
    required List<ApplianceItem> essentialAppliances,
    required UpsBattery battery,
    double outagesPerDay = 2.0,
  }) {
    double activeLoad = 0.0;
    for (final item in essentialAppliances) {
      activeLoad += (item.watts * item.quantity);
    }

    final backupHours = battery.calculateBackupHours(activeLoad);
    final rechargePerOutage = battery.calculateRechargeKwh();
    final monthlyRechargeKwh = rechargePerOutage * outagesPerDay * 30.0;

    return BackupResult(
      activeLoadWatts: activeLoad,
      backupHours: backupHours,
      rechargeKwhPerOutage: rechargePerOutage,
      monthlyRechargeKwh: monthlyRechargeKwh,
    );
  }
}
