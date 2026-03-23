class Category {
  final String id;
  final String seasonId;
  final String name;
  final int plannedBudget;
  final String? color; // Mã màu hex: #RRGGBB
  final String? icon;  // Tên icon hoặc mã icon
  final String? note;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  Category({
    required this.id,
    required this.seasonId,
    required this.name,
    this.plannedBudget = 0,
    this.color,
    this.icon,
    this.note,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      name: map['name'] as String,
      plannedBudget: map['planned_budget'] as int? ?? 0,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      note: map['note'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'name': name,
      'planned_budget': plannedBudget,
      'color': color,
      'icon': icon,
      'note': note,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Category copyWith({
    String? name,
    int? plannedBudget,
    String? color,
    String? icon,
    String? note,
    int? sortOrder,
    int? updatedAt,
  }) {
    return Category(
      id: id,
      seasonId: seasonId,
      name: name ?? this.name,
      plannedBudget: plannedBudget ?? this.plannedBudget,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
