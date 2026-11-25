import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/services/hive_storage_service.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('billshield.db');
    return _database!;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) return null;

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {}

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute(
                  'ALTER TABLE bills ADD COLUMN is_three_phase INTEGER DEFAULT 0');
              await db.execute(
                  'ALTER TABLE bills ADD COLUMN is_6month_locked INTEGER DEFAULT 0');
            } catch (_) {}
          }
        },
      );
    } catch (e) {
      debugPrint('SQLite initialization bypassed: $e');
      return null;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT NOT NULL,
        total_units REAL NOT NULL,
        peak_units REAL NOT NULL,
        off_peak_units REAL NOT NULL,
        is_protected INTEGER NOT NULL,
        is_three_phase INTEGER DEFAULT 0,
        is_6month_locked INTEGER DEFAULT 0,
        base_energy_charge REAL NOT NULL,
        fpa_charge REAL NOT NULL,
        qta_charge REAL NOT NULL,
        fixed_charges REAL NOT NULL,
        meter_rent REAL NOT NULL,
        tv_fee REAL NOT NULL,
        electricity_duty REAL NOT NULL,
        gst_and_duties REAL NOT NULL,
        total_bill REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE active_appliances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        watts REAL NOT NULL,
        quantity INTEGER NOT NULL,
        daily_hours REAL NOT NULL,
        is_peak_hours INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // Bill Operations
  Future<int> insertBill(BillCalculation calculation) async {
    if (kIsWeb) {
      await HiveStorageService.saveBill(calculation);
      return 1;
    }
    final db = await instance.database;
    if (db == null) {
      await HiveStorageService.saveBill(calculation);
      return 1;
    }
    return await db.insert('bills', {
      'provider': calculation.provider,
      'total_units': calculation.totalUnits,
      'peak_units': calculation.peakUnits,
      'off_peak_units': calculation.offPeakUnits,
      'is_protected': calculation.isProtected ? 1 : 0,
      'is_three_phase': calculation.isThreePhase ? 1 : 0,
      'is_6month_locked': calculation.is6MonthUnprotectedLocked ? 1 : 0,
      'base_energy_charge': calculation.baseEnergyCharge,
      'fpa_charge': calculation.fpaCharge,
      'qta_charge': calculation.qtaCharge,
      'fixed_charges': calculation.fixedCharges,
      'meter_rent': calculation.meterRent,
      'tv_fee': calculation.tvFee,
      'electricity_duty': calculation.electricityDuty,
      'gst_and_duties': calculation.gstAndDuties,
      'total_bill': calculation.totalBill,
      'timestamp': calculation.timestamp.toIso8601String(),
    });
  }

  Future<List<BillCalculation>> getSavedBills() async {
    if (kIsWeb) {
      return HiveStorageService.getSavedBills();
    }
    final db = await instance.database;
    if (db == null) {
      return HiveStorageService.getSavedBills();
    }
    final maps = await db.query('bills', orderBy: 'timestamp DESC');
    return maps.map((map) {
      return BillCalculation(
        id: map['id'] as int?,
        provider: map['provider'] as String,
        totalUnits: (map['total_units'] as num).toDouble(),
        peakUnits: (map['peak_units'] as num).toDouble(),
        offPeakUnits: (map['off_peak_units'] as num).toDouble(),
        isProtected: (map['is_protected'] as int) == 1,
        isThreePhase: (map['is_three_phase'] as int?) == 1,
        is6MonthUnprotectedLocked: (map['is_6month_locked'] as int?) == 1,
        excessUnitsOverProtected: (map['total_units'] as num).toDouble() > 200.0
            ? (map['total_units'] as num).toDouble() - 200.0
            : 0.0,
        estimatedSavingsIfProtected: 0.0,
        baseEnergyCharge: (map['base_energy_charge'] as num).toDouble(),
        fpaCharge: (map['fpa_charge'] as num).toDouble(),
        qtaCharge: (map['qta_charge'] as num).toDouble(),
        fixedCharges: (map['fixed_charges'] as num).toDouble(),
        meterRent: (map['meter_rent'] as num).toDouble(),
        tvFee: (map['tv_fee'] as num?)?.toDouble() ?? 35.0,
        electricityDuty: (map['electricity_duty'] as num?)?.toDouble() ?? 0.0,
        gstAndDuties: (map['gst_and_duties'] as num).toDouble(),
        totalBill: (map['total_bill'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList();
  }

  Future<int> deleteBill(int id) async {
    if (kIsWeb) return 1;
    final db = await instance.database;
    if (db == null) return 1;
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllBills() async {
    if (kIsWeb) {
      await HiveStorageService.clearAllBills();
      return;
    }
    final db = await instance.database;
    if (db == null) {
      await HiveStorageService.clearAllBills();
      return;
    }
    await db.delete('bills');
  }

  // Active Appliances Operations
  Future<void> saveActiveAppliances(List<ApplianceItem> appliances) async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('active_appliances');
      for (final item in appliances) {
        await txn.insert('active_appliances', {
          'name': item.name,
          'watts': item.watts,
          'quantity': item.quantity,
          'daily_hours': item.dailyHours,
          'is_peak_hours': item.isPeakHours ? 1 : 0,
        });
      }
    });
  }

  Future<List<ApplianceItem>> getActiveAppliances() async {
    if (kIsWeb) {
      final workspace = HiveStorageService.loadWorkspace();
      return (workspace?['appliances'] as List<ApplianceItem>?) ?? [];
    }
    final db = await instance.database;
    if (db == null) {
      final workspace = HiveStorageService.loadWorkspace();
      return (workspace?['appliances'] as List<ApplianceItem>?) ?? [];
    }
    final maps = await db.query('active_appliances');
    return maps.map((map) {
      return ApplianceItem(
        id: map['id']?.toString(),
        name: map['name'] as String,
        watts: (map['watts'] as num).toDouble(),
        quantity: map['quantity'] as int,
        dailyHours: (map['daily_hours'] as num).toDouble(),
        isPeakHours: (map['is_peak_hours'] as int) == 1,
      );
    }).toList();
  }

  // Settings Key-Value Operations
  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
