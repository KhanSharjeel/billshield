class MeterReading {
  final DateTime readingDate;
  final int consumedUnits;
  final double totalBilledAmount;

  MeterReading({
    required this.readingDate,
    required this.consumedUnits,
    required this.totalBilledAmount,
  });

  Map<String, dynamic> toJson() => {
    'readingDate': readingDate.toIso8601String(),
    'consumedUnits': consumedUnits,
    'totalBilledAmount': totalBilledAmount,
  };

  factory MeterReading.fromJson(Map<String, dynamic> json) => MeterReading(
    readingDate: DateTime.parse(json['readingDate']),
    consumedUnits: json['consumedUnits'],
    totalBilledAmount: (json['totalBilledAmount'] as num).toDouble(),
  );
}