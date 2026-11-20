class ApplianceItem {
  final String name;
  final double watts;
  final int quantity;
  final double dailyHours;
  final bool isPeakHours;

  const ApplianceItem({
    required this.name,
    required this.watts,
    required this.quantity,
    required this.dailyHours,
    this.isPeakHours = false,
  });

  double get monthlyUnits {
    if (watts <= 0 || quantity <= 0 || dailyHours <= 0) return 0;
    return (watts * quantity * dailyHours * 30) / 1000.0;
  }

  ApplianceItem copyWith({
    String? name,
    double? watts,
    int? quantity,
    double? dailyHours,
    bool? isPeakHours,
  }) {
    return ApplianceItem(
      name: name ?? this.name,
      watts: watts ?? this.watts,
      quantity: quantity ?? this.quantity,
      dailyHours: dailyHours ?? this.dailyHours,
      isPeakHours: isPeakHours ?? this.isPeakHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'watts': watts,
      'quantity': quantity,
      'dailyHours': dailyHours,
      'isPeakHours': isPeakHours,
    };
  }

  factory ApplianceItem.fromMap(Map<dynamic, dynamic> map) {
    return ApplianceItem(
      name: map['name'] as String? ?? 'Appliance',
      watts: (map['watts'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      dailyHours: (map['dailyHours'] as num?)?.toDouble() ?? 0.0,
      isPeakHours: map['isPeakHours'] as bool? ?? false,
    );
  }
}