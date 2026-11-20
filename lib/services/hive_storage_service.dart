import 'package:hive_flutter/hive_flutter.dart';
import 'package:billshield/models/bill_calculation.dart';

class HiveStorageService {
  static const String _boxName = 'saved_bills';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> saveBill(BillCalculation calculation) async {
    await _box.add(calculation.toMap());
  }

  static List<BillCalculation> getSavedBills() {
    return _box.values
        .whereType()
        .map((e) => BillCalculation.fromMap(e))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> deleteBillAt(int reversedIndex) async {
    final actualIndex = _box.length - 1 - reversedIndex;
    if (actualIndex >= 0 && actualIndex < _box.length) {
      await _box.deleteAt(actualIndex);
    }
  }
}