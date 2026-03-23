import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('san_sale_tet.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Seasons
    await db.execute('''
      CREATE TABLE seasons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        budget_limit INTEGER,
        currency TEXT NOT NULL DEFAULT 'VND',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. Categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        season_id TEXT NOT NULL,
        name TEXT NOT NULL,
        planned_budget INTEGER NOT NULL DEFAULT 0,
        color TEXT,
        icon TEXT,
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_categories_season ON categories(season_id)');

    // 3. Items
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        season_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        target_price INTEGER NOT NULL,
        current_price INTEGER,
        current_updated_at INTEGER,
        status TEXT NOT NULL DEFAULT 'todo',
        priority TEXT NOT NULL DEFAULT 'medium',
        is_essential INTEGER NOT NULL DEFAULT 0,
        store TEXT,
        link TEXT,
        note TEXT,
        image_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('CREATE INDEX idx_items_season ON items(season_id)');
    await db.execute('CREATE INDEX idx_items_category ON items(category_id)');

    // 4. Expenses ... (remains same)
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        season_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        item_id TEXT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        quantity INTEGER,
        unit_price INTEGER,
        amount INTEGER NOT NULL,
        store TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_season ON expenses(season_id)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category_id)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');

    // 5. Photos
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        season_id TEXT NOT NULL,
        type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        expense_id TEXT,
        item_id TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_photos_season ON photos(season_id)');
    await db.execute('CREATE INDEX idx_photos_expense ON photos(expense_id)');
    await db.execute('CREATE INDEX idx_photos_item ON photos(item_id)');

    // 6. Price History
    await db.execute('''
      CREATE TABLE price_history (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        season_id TEXT NOT NULL,
        price INTEGER NOT NULL,
        store TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_price_item ON price_history(item_id)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE seasons ADD COLUMN budget_limit INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE items ADD COLUMN priority TEXT NOT NULL DEFAULT "medium"');
      await db.execute('ALTER TABLE items ADD COLUMN is_essential INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE categories ADD COLUMN color TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN icon TEXT');
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }
}
