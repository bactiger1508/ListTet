class PriceHistory {
  final String id;
  final String itemId;
  final String seasonId;
  final int price;
  final String? store;
  final int createdAt;

  PriceHistory({
    required this.id,
    required this.itemId,
    required this.seasonId,
    required this.price,
    this.store,
    required this.createdAt,
  });

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      seasonId: map['season_id'] as String,
      price: map['price'] as int,
      store: map['store'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'season_id': seasonId,
      'price': price,
      'store': store,
      'created_at': createdAt,
    };
  }
}
