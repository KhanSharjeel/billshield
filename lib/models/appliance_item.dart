class ApplianceItem {
  final String? id;
  final String name;
  final double watts;
  final int quantity;
  final double dailyHours;
  final bool isPeakHours;

  const ApplianceItem({
    this.id,
    required this.name,
    required this.watts,
    required this.quantity,
    required this.dailyHours,
    this.isPeakHours = false,
  });

  double get monthlyUnits {
    if (watts <= 0 || quantity <= 0 || dailyHours <= 0) return 0.0;
    return (watts * quantity * dailyHours * 30.0) / 1000.0;
  }

  double get dailyUnits {
    if (watts <= 0 || quantity <= 0 || dailyHours <= 0) return 0.0;
    return (watts * quantity * dailyHours) / 1000.0;
  }

  ApplianceItem copyWith({
    String? id,
    String? name,
    double? watts,
    int? quantity,
    double? dailyHours,
    bool? isPeakHours,
  }) {
    return ApplianceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      watts: watts ?? this.watts,
      quantity: quantity ?? this.quantity,
      dailyHours: dailyHours ?? this.dailyHours,
      isPeakHours: isPeakHours ?? this.isPeakHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'watts': watts,
      'quantity': quantity,
      'dailyHours': dailyHours,
      'isPeakHours': isPeakHours,
    };
  }

  factory ApplianceItem.fromMap(Map<dynamic, dynamic> map) {
    return ApplianceItem(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? 'Appliance',
      watts: (map['watts'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      dailyHours: (map['dailyHours'] as num?)?.toDouble() ?? 0.0,
      isPeakHours: map['isPeakHours'] as bool? ?? false,
    );
  }

  static const List<ApplianceItem> quickAddPresets = [
    ApplianceItem(
      name: '1.5 Ton Inverter AC',
      watts: 1500,
      quantity: 1,
      dailyHours: 6.0,
      isPeakHours: true,
    ),
    ApplianceItem(
      name: 'Ceiling Fan',
      watts: 75,
      quantity: 1,
      dailyHours: 12.0,
    ),
    ApplianceItem(
      name: 'Refrigerator',
      watts: 160,
      quantity: 1,
      dailyHours: 14.0,
    ),
    ApplianceItem(
      name: 'Electric Iron',
      watts: 1000,
      quantity: 1,
      dailyHours: 1.0,
    ),
    ApplianceItem(
      name: 'Water Pump (1 HP)',
      watts: 746,
      quantity: 1,
      dailyHours: 1.0,
    ),
    ApplianceItem(
      name: 'LED TV',
      watts: 80,
      quantity: 1,
      dailyHours: 4.0,
      isPeakHours: true,
    ),
    ApplianceItem(
      name: 'LED Bulbs (Pack)',
      watts: 12,
      quantity: 6,
      dailyHours: 6.0,
    ),
    ApplianceItem(
      name: 'Washing Machine',
      watts: 500,
      quantity: 1,
      dailyHours: 1.0,
    ),
  ];
}
