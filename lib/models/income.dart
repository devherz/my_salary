class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isRecurringSalary; // true if base salary, false if additional income
  final String? note;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.isRecurringSalary = false,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'isRecurringSalary': isRecurringSalary,
        'note': note,
      };

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isRecurringSalary: json['isRecurringSalary'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
