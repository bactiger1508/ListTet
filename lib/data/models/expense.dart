class Expense {
  final String id;
  final String seasonId;
  final String categoryId;
  final String? itemId;
  final String title;
  final String date; // YYYY-MM-DD
  final int? quantity;
  final int? unitPrice;
  final int amount;
  final String? store;
  final String? note;
  final int createdAt;
  final int updatedAt;

  final String? itemImagePath;

  Expense({
    required this.id,
    required this.seasonId,
    required this.categoryId,
    this.itemId,
    required this.title,
    required this.date,
    this.quantity,
    this.unitPrice,
    required this.amount,
    this.store,
    this.note,
    this.itemImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      categoryId: map['category_id'] as String,
      itemId: map['item_id'] as String?,
      title: map['title'] as String,
      date: map['date'] as String,
      quantity: map['quantity'] as int?,
      unitPrice: map['unit_price'] as int?,
      amount: map['amount'] as int,
      store: map['store'] as String?,
      note: map['note'] as String?,
      itemImagePath: map['item_image_path'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'category_id': categoryId,
      'item_id': itemId,
      'title': title,
      'date': date,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'store': store,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Expense copyWith({
    String? categoryId,
    String? itemId,
    String? title,
    String? date,
    int? quantity,
    int? unitPrice,
    int? amount,
    String? store,
    String? note,
    int? updatedAt,
  }) {
    return Expense(
      id: id,
      seasonId: seasonId,
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      store: store ?? this.store,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
