class Season {
  final String id;
  final String name;
  final String? startDate;
  final String? endDate;
  final int? budgetLimit;
  final String currency;
  final int createdAt;
  final int updatedAt;

  Season({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.budgetLimit,
    this.currency = 'VND',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Season.fromMap(Map<String, dynamic> map) {
    return Season(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      budgetLimit: map['budget_limit'] as int?,
      currency: map['currency'] as String? ?? 'VND',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'budget_limit': budgetLimit,
      'currency': currency,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Season copyWith({
    String? name,
    String? startDate,
    String? endDate,
    int? budgetLimit,
    String? currency,
    int? updatedAt,
  }) {
    return Season(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
