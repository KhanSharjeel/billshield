import 'package:hive_flutter/hive_flutter.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/bill_calculation.dart';

class HiveStorageService {
  static const String _billsBoxName = 'saved_bills';
  static const String _workspaceBoxName = 'active_workspace';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_billsBoxName);
    await Hive.openBox(_workspaceBoxName);
  }

  static Box get _billsBox => Hive.box(_billsBoxName);
  static Box get _workspaceBox => Hive.box(_workspaceBoxName);

  static Future<void> saveBill(BillCalculation calculation) async {
    await _billsBox.add(calculation.toMap());
  }

  static List<BillCalculation> getSavedBills() {
    return _billsBox.values
        .whereType()
        .map((e) => BillCalculation.fromMap(e))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> deleteBillAt(int reversedIndex) async {
    final actualIndex = _billsBox.length - 1 - reversedIndex;
    if (actualIndex >= 0 && actualIndex < _billsBox.length) {
      await _billsBox.deleteAt(actualIndex);
    }
  }

  static Future<void> saveWorkspace({
    required String provider,
    required List<ApplianceItem> appliances,
    required double fpaRate,
    required double qtaRate,
    required double fixedCharges,
    required bool includeMeterRent,
  }) async {
    await _workspaceBox.putAll({
      'provider': provider,
      'appliances': appliances.map((a) => a.toMap()).toList(),
      'fpaRate': fpaRate,
      'qtaRate': qtaRate,
      'fixedCharges': fixedCharges,
      'includeMeterRent': includeMeterRent,
    });
  }

  static Map<String, dynamic>? loadWorkspace() {
    if (_workspaceBox.isEmpty) return null;
    final rawAppliances = _workspaceBox.get('appliances');
    final parsedAppliances = rawAppliances is List
        ? rawAppliances
        .whereType()
        .map((m) => ApplianceItem.fromMap(m))
        .toList()
        : <ApplianceItem>[];

    return {
      'provider': _workspaceBox.get('provider') as String?,
      'appliances': parsedAppliances,
      'fpaRate': (_workspaceBox.get('fpaRate') as num?)?.toDouble() ?? 2.50,
      'qtaRate': (_workspaceBox.get('qtaRate') as num?)?.toDouble() ?? 1.75,
      'fixedCharges':
      (_workspaceBox.get('fixedCharges') as num?)?.toDouble() ?? 0.0,
      'includeMeterRent':
      _workspaceBox.get('includeMeterRent') as bool? ?? true,
    };
  }
}