class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isRecurringSalary; // true if base salary, false if additional income
  final String? note;
  final double needsRatio;   // default 50.0 (%)
  final double wantsRatio;   // default 30.0 (%)
  final double savingsRatio; // default 20.0 (%)

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.isRecurringSalary = false,
    this.note,
    this.needsRatio = 50.0,
    this.wantsRatio = 30.0,
    this.savingsRatio = 20.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'isRecurringSalary': isRecurringSalary,
        'note': note,
        'needsRatio': needsRatio,
        'wantsRatio': wantsRatio,
        'savingsRatio': savingsRatio,
      };

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isRecurringSalary: json['isRecurringSalary'] as bool? ?? false,
      note: json['note'] as String?,
      needsRatio: (json['needsRatio'] as num?)?.toDouble() ?? 50.0,
      wantsRatio: (json['wantsRatio'] as num?)?.toDouble() ?? 30.0,
      savingsRatio: (json['savingsRatio'] as num?)?.toDouble() ?? 20.0,
    );
  }
}
