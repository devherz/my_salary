class CategoryBudgetCap {
  final String category;
  final double limitAmount;
  final String? incomeSourceId;

  CategoryBudgetCap({
    required this.category,
    required this.limitAmount,
    this.incomeSourceId,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'limitAmount': limitAmount,
        'incomeSourceId': incomeSourceId,
      };

  factory CategoryBudgetCap.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetCap(
      category: json['category'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      incomeSourceId: json['incomeSourceId'] as String?,
    );
  }
}
