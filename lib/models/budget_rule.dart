enum BudgetCategoryType {
  needs,   // Besoins (50%)
  wants,   // Envies / Loisirs (30%)
  savings, // Épargne & Investissements (20%)
}

extension BudgetCategoryTypeExtension on BudgetCategoryType {
  String get displayName {
    switch (this) {
      case BudgetCategoryType.needs:
        return 'Besoins';
      case BudgetCategoryType.wants:
        return 'Envies / Loisirs';
      case BudgetCategoryType.savings:
        return 'Épargne';
    }
  }

  String get description {
    switch (this) {
      case BudgetCategoryType.needs:
        return 'Logement, factures, nourriture, transport...';
      case BudgetCategoryType.wants:
        return 'Sorties, shopping, divertissement, loisirs...';
      case BudgetCategoryType.savings:
        return 'Fonds d\'urgence, investissements, projets...';
    }
  }
}

class BudgetRule {
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;

  const BudgetRule({
    this.needsPercent = 50.0,
    this.wantsPercent = 30.0,
    this.savingsPercent = 20.0,
  });

  Map<String, dynamic> toJson() => {
        'needsPercent': needsPercent,
        'wantsPercent': wantsPercent,
        'savingsPercent': savingsPercent,
      };

  factory BudgetRule.fromJson(Map<String, dynamic> json) {
    return BudgetRule(
      needsPercent: (json['needsPercent'] as num?)?.toDouble() ?? 50.0,
      wantsPercent: (json['wantsPercent'] as num?)?.toDouble() ?? 30.0,
      savingsPercent: (json['savingsPercent'] as num?)?.toDouble() ?? 20.0,
    );
  }

  BudgetRule copyWith({
    double? needsPercent,
    double? wantsPercent,
    double? savingsPercent,
  }) {
    return BudgetRule(
      needsPercent: needsPercent ?? this.needsPercent,
      wantsPercent: wantsPercent ?? this.wantsPercent,
      savingsPercent: savingsPercent ?? this.savingsPercent,
    );
  }
}
