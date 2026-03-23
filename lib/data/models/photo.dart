class Photo {
  final String id;
  final String seasonId;
  final String type; // receipt | product
  final String localPath;
  final String? expenseId;
  final String? itemId;
  final String? note;
  final int createdAt;

  Photo({
    required this.id,
    required this.seasonId,
    required this.type,
    required this.localPath,
    this.expenseId,
    this.itemId,
    this.note,
    required this.createdAt,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      type: map['type'] as String,
      localPath: map['local_path'] as String,
      expenseId: map['expense_id'] as String?,
      itemId: map['item_id'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'type': type,
      'local_path': localPath,
      'expense_id': expenseId,
      'item_id': itemId,
      'note': note,
      'created_at': createdAt,
    };
  }
}
