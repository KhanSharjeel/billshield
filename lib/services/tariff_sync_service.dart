import 'package:flutter/foundation.dart';
import 'package:billshield/services/hive_storage_service.dart';

class TariffSyncService {
  static const double defaultFpaRate = 2.50;
  static const double defaultQtaRate = 1.75;

  static Future<Map<String, double>> getLatestTariffs() async {
    // Offline-first: returns cached workspace rates or defaults
    final workspace = HiveStorageService.loadWorkspace();
    final fpa = (workspace?['fpaRate'] as num?)?.toDouble() ?? defaultFpaRate;
    final qta = (workspace?['qtaRate'] as num?)?.toDouble() ?? defaultQtaRate;
    return {
      'fpaRate': fpa,
      'qtaRate': qta,
    };
  }

  static Future<void> syncRemoteTariffs() async {
    // Simulated background OTA JSON sync for monthly NEPRA notifications
    try {
      debugPrint('Syncing NEPRA tariff updates in background...');
    } catch (_) {}
  }
}
