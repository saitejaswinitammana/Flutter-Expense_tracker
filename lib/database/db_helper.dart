import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

/// Database Helper implementing the Singleton design pattern.
/// Handles SQLite database operations on mobile/desktop and an in-memory fallback on web.
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Cached database reference
  static Database? _database;

  // In-memory store for Web execution (where SQLite FFI is unavailable)
  final List<Expense> _webStore = [
    Expense(
      id: 1,
      title: 'Weekly Grocery Haul',
      amount: 48.75,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Fresh fruits and milk',
    ),
    Expense(
      id: 2,
      title: 'Metro Smart Card Recharge',
      amount: 20.00,
      category: 'Travel',
      date: DateTime.now().subtract(const Duration(days: 2)),
      note: 'Monthly transit',
    ),
    Expense(
      id: 3,
      title: 'Electricity Utility Bill',
      amount: 65.20,
      category: 'Bills',
      date: DateTime.now().subtract(const Duration(days: 5)),
      note: 'October billing cycle',
    ),
  ];
  int _nextWebId = 4;

  // Private constructor ensures only one instance exists throughout the app
  DatabaseHelper._init();

  // Table and column constants for clean refactoring and zero typos
  static const String tableName = 'expenses';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDate = 'date';
  static const String colNote = 'note';

  /// Getter for the database; initializes it if not already opened.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  /// Initialize SQLite database at the platform-appropriate databases path.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Callback executed when the database file is first created on the device.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colCategory TEXT NOT NULL,
        $colDate TEXT NOT NULL,
        $colNote TEXT
      )
    ''');
  }

  // ==========================================
  // CRUD OPERATIONS
  // ==========================================

  /// [CREATE]: Insert a new expense into the database.
  Future<int> insert(Expense expense) async {
    if (kIsWeb) {
      final newId = _nextWebId++;
      _webStore.add(expense.copyWith(id: newId));
      return newId;
    }

    final db = await database;
    return await db.insert(
      tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// [READ]: Fetch all expenses, optionally filtered by category.
  /// Sorted newest first.
  Future<List<Expense>> getAll({String? category}) async {
    if (kIsWeb) {
      var list = List<Expense>.from(_webStore);
      if (category != null && category.isNotEmpty && category != 'All') {
        list = list.where((e) => e.category == category).toList();
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }

    final db = await database;
    List<Map<String, dynamic>> maps;

    if (category != null && category.isNotEmpty && category != 'All') {
      maps = await db.query(
        tableName,
        where: '$colCategory = ?',
        whereArgs: [category],
        orderBy: '$colDate DESC, $colId DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        orderBy: '$colDate DESC, $colId DESC',
      );
    }

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// [READ]: Fetch a single expense by its ID.
  Future<Expense?> getById(int id) async {
    if (kIsWeb) {
      try {
        return _webStore.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final maps = await db.query(
      tableName,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  /// [UPDATE]: Update an existing expense record by ID.
  Future<int> update(Expense expense) async {
    if (kIsWeb) {
      final index = _webStore.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _webStore[index] = expense;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      tableName,
      expense.toMap(),
      where: '$colId = ?',
      whereArgs: [expense.id],
    );
  }

  /// [DELETE]: Delete an expense record by its ID.
  Future<int> delete(int id) async {
    if (kIsWeb) {
      _webStore.removeWhere((e) => e.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      tableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Compute total money spent, optionally filtered by category.
  Future<double> getTotalSpent({String? category}) async {
    if (kIsWeb) {
      final list = (category != null && category.isNotEmpty && category != 'All')
          ? _webStore.where((e) => e.category == category)
          : _webStore;
      return list.fold<double>(0.0, (sum, item) => sum + item.amount);
    }

    final db = await database;
    String sql = 'SELECT SUM($colAmount) as total FROM $tableName';
    List<dynamic> arguments = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      sql += ' WHERE $colCategory = ?';
      arguments.add(category);
    }

    final result = await db.rawQuery(sql, arguments);
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  /// Close the database connection when no longer needed.
  Future<void> close() async {
    if (!kIsWeb) {
      final db = await database;
      await db.close();
    }
  }
}
