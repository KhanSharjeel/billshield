class MeterReading {
  final int consumedUnits;
  final double totalBilledAmount;

  MeterReading({
    required this.consumedUnits,
    required this.totalBilledAmount,
  });

  Map<String, dynamic> toJson() => {
    'consumedUnits': consumedUnits,
    'totalBilledAmount': totalBilledAmount,
  };
}