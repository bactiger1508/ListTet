enum ItemStatus { todo, watching, bought, dropped }

enum ItemPriority { low, medium, high }

extension ItemPriorityExt on ItemPriority {
  String get value => toString().split('.').last;
  String get label {
    switch (this) {
      case ItemPriority.high: return 'Ưu tiên cao';
      case ItemPriority.medium: return 'Trung bình';
      case ItemPriority.low: return 'Thấp';
    }
  }
  static ItemPriority fromString(String s) {
    return ItemPriority.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ItemPriority.medium,
    );
  }
}

extension ItemStatusExt on ItemStatus {
  String get value {
    switch (this) {
      case ItemStatus.todo: return 'todo';
      case ItemStatus.watching: return 'watching';
      case ItemStatus.bought: return 'bought';
      case ItemStatus.dropped: return 'dropped';
    }
  }

  String get label {
    switch (this) {
      case ItemStatus.todo: return 'Cần mua';
      case ItemStatus.watching: return 'Đang theo dõi';
      case ItemStatus.bought: return 'Đã mua';
      case ItemStatus.dropped: return 'Đã bỏ';
    }
  }

  static ItemStatus fromString(String s) {
    switch (s) {
      case 'watching': return ItemStatus.watching;
      case 'bought': return ItemStatus.bought;
      case 'dropped': return ItemStatus.dropped;
      default: return ItemStatus.todo;
    }
  }
}

class Item {
  final String id;
  final String seasonId;
  final String categoryId;
  final String name;
  final int quantity;
  final int targetPrice;
  final int? currentPrice;
  final int? currentUpdatedAt;
  final ItemStatus status;
  final ItemPriority priority;
  final bool isEssential; // Món đồ bắt buộc phải có
  final String? store;
  final String? link;
  final String? note;
  final String? imagePath;
  final int createdAt;
  final int updatedAt;

  Item({
    required this.id,
    required this.seasonId,
    required this.categoryId,
    required this.name,
    this.quantity = 1,
    required this.targetPrice,
    this.currentPrice,
    this.currentUpdatedAt,
    this.status = ItemStatus.todo,
    this.priority = ItemPriority.medium,
    this.isEssential = false,
    this.store,
    this.link,
    this.note,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 'green' = currentPrice <= targetPrice, 'yellow' = within 5%, 'red' = above, 'none' = no price
  String get dealLevel {
    if (currentPrice == null) return 'không';
    if (currentPrice! <= targetPrice) return 'tốt';
    if (currentPrice! <= (targetPrice * 1.05).toInt()) return 'ổn';
    return 'cao';
  }

  /// How much saved (positive) or overpaid (negative) vs target
  int get savings => currentPrice != null ? (targetPrice - currentPrice!) * quantity : 0;
  
  int get totalTargetPrice => targetPrice * quantity;
  int? get totalCurrentPrice => currentPrice != null ? currentPrice! * quantity : null;

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int? ?? 1,
      targetPrice: map['target_price'] as int,
      currentPrice: map['current_price'] as int?,
      currentUpdatedAt: map['current_updated_at'] as int?,
      status: ItemStatusExt.fromString(map['status'] as String? ?? 'todo'),
      priority: ItemPriorityExt.fromString(map['priority'] as String? ?? 'medium'),
      isEssential: (map['is_essential'] as int? ?? 0) == 1,
      store: map['store'] as String?,
      link: map['link'] as String?,
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'category_id': categoryId,
      'name': name,
      'quantity': quantity,
      'target_price': targetPrice,
      'current_price': currentPrice,
      'current_updated_at': currentUpdatedAt,
      'status': status.value,
      'priority': priority.value,
      'is_essential': isEssential ? 1 : 0,
      'store': store,
      'link': link,
      'note': note,
      'image_path': imagePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Item copyWith({
    String? categoryId,
    String? name,
    int? quantity,
    int? targetPrice,
    int? currentPrice,
    int? currentUpdatedAt,
    ItemStatus? status,
    ItemPriority? priority,
    bool? isEssential,
    String? store,
    String? link,
    String? note,
    String? imagePath,
    int? updatedAt,
  }) {
    return Item(
      id: id,
      seasonId: seasonId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      targetPrice: targetPrice ?? this.targetPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      currentUpdatedAt: currentUpdatedAt ?? this.currentUpdatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isEssential: isEssential ?? this.isEssential,
      store: store ?? this.store,
      link: link ?? this.link,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
