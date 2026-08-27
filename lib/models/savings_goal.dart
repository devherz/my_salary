class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? startDate;
  final DateTime? targetDate;
  final double? monthlyAmount;
  final int colorHex;
  final String iconName;
  final String? incomeSourceId;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.startDate,
    this.targetDate,
    this.monthlyAmount,
    this.colorHex = 0xFF4CAF50, // Default emerald green
    this.iconName = 'savings',
    this.incomeSourceId,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentAmount >= targetAmount;

  double get calculatedMonthlyTarget {
    if (monthlyAmount != null && monthlyAmount! > 0) {
      return monthlyAmount!;
    }
    if (targetDate == null) return 0.0;

    final start = startDate ?? DateTime.now();
    int months = (targetDate!.year - start.year) * 12 + (targetDate!.month - start.month);
    if (months <= 0) months = 1;
    final remainingToSave = targetAmount - currentAmount;
    if (remainingToSave <= 0) return 0.0;
    return remainingToSave / months;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'startDate': startDate?.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'monthlyAmount': monthlyAmount,
        'colorHex': colorHex,
        'iconName': iconName,
        'incomeSourceId': incomeSourceId,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble(),
      colorHex: (json['colorHex'] as int?) ?? 0xFF4CAF50,
      iconName: (json['iconName'] as String?) ?? 'savings',
      incomeSourceId: json['incomeSourceId'] as String?,
    );
  }

  SavingsGoal copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    double? monthlyAmount,
    int? colorHex,
    String? iconName,
    String? incomeSourceId,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
    );
  }
}
