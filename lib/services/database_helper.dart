import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        accountNumber TEXT,
        currency TEXT NOT NULL,
        color TEXT NOT NULL,
        balance REAL NOT NULL,
        isArchived INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        parentId TEXT,
        isArchived INTEGER NOT NULL
      )
    ''');

    // Records (Transactions) Table
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        accountId TEXT NOT NULL,
        fromAccountId TEXT,
        toAccountId TEXT,
        categoryId TEXT,
        note TEXT,
        dateTime TEXT NOT NULL,
        templateId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Templates Table
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL,
        accountId TEXT,
        categoryId TEXT,
        note TEXT
      )
    ''');

    // Planned Payments Table
    await db.execute('''
      CREATE TABLE planned_payments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        accountId TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        notes TEXT,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        recurrence TEXT,
        endType TEXT NOT NULL,
        endDate TEXT,
        endOccurrences INTEGER,
        label TEXT
      )
    ''');

    // Debts Table
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        borrowerName TEXT NOT NULL,
        notes TEXT,
        accountId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        paidToAccountId TEXT,
        recordId TEXT NOT NULL,
        paidRecordId TEXT
      )
    ''');

    // Credits Table
    await db.execute('''
      CREATE TABLE credits (
        id TEXT PRIMARY KEY,
        lenderName TEXT NOT NULL,
        notes TEXT,
        accountId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        paidFromAccountId TEXT,
        recordId TEXT NOT NULL,
        paidRecordId TEXT
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  Future _seedDefaultCategories(Database db) async {
    final uuid = const Uuid();
    final defaultCategories = [
      Category(id: uuid.v4(), name: 'Food & Dining', color: '0xFFFF5722', icon: 'restaurant', isArchived: false),
      Category(id: uuid.v4(), name: 'Shopping', color: '0xFF2196F3', icon: 'shopping_bag', isArchived: false),
      Category(id: uuid.v4(), name: 'Transportation', color: '0xFF4CAF50', icon: 'directions_car', isArchived: false),
      Category(id: uuid.v4(), name: 'Entertainment', color: '0xFF9C27B0', icon: 'sports_esports', isArchived: false),
      Category(id: uuid.v4(), name: 'Bills & Utilities', color: '0xFFFFC107', icon: 'electrical_services', isArchived: false),
      Category(id: uuid.v4(), name: 'Salary & Income', color: '0xFF009688', icon: 'monetization_on', isArchived: false),
      Category(id: uuid.v4(), name: 'Others', color: '0xFF9E9E9E', icon: 'category', isArchived: false),
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
