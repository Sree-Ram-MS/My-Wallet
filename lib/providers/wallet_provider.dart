import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/record.dart';
import '../models/category.dart';
import '../models/template.dart';
import '../models/planned_payment.dart';
import '../models/debt.dart';
import '../models/credit.dart';
import '../services/database_helper.dart';

class WalletProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Record> _records = [];
  List<Category> _categories = [];
  List<Template> _templates = [];
  List<PlannedPayment> _plannedPayments = [];
  List<Debt> _debts = [];
  List<Credit> _credits = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts.where((a) => !a.isArchived).toList();
  List<Account> get archivedAccounts => _accounts.where((a) => a.isArchived).toList();
  List<Record> get records => _records;
  List<Category> get categories => _categories.where((c) => !c.isArchived).toList();
  List<Template> get templates => _templates;
  List<PlannedPayment> get plannedPayments => _plannedPayments;
  List<Debt> get debts => _debts;
  List<Credit> get credits => _credits;
  bool get isLoading => _isLoading;

  final uuid = const Uuid();

  /// Loads all local financial data from SQLite
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;

      // Load Accounts
      final List<Map<String, dynamic>> accountMaps = await db.query('accounts', orderBy: 'createdAt DESC');
      _accounts = accountMaps.map((map) => Account.fromMap(map)).toList();

      // Load Categories
      final List<Map<String, dynamic>> categoryMaps = await db.query('categories');
      _categories = categoryMaps.map((map) => Category.fromMap(map)).toList();

      // Load Records (Transactions)
      final List<Map<String, dynamic>> recordMaps = await db.query('records', orderBy: 'dateTime DESC');
      _records = recordMaps.map((map) => Record.fromMap(map)).toList();

      // Load Templates
      final List<Map<String, dynamic>> templateMaps = await db.query('templates');
      _templates = templateMaps.map((map) => Template.fromMap(map)).toList();

      // Load Planned Payments
      final List<Map<String, dynamic>> plannedMaps = await db.query('planned_payments');
      _plannedPayments = plannedMaps.map((map) => PlannedPayment.fromMap(map)).toList();

      // Load Debts
      final List<Map<String, dynamic>> debtMaps = await db.query('debts', orderBy: 'date DESC');
      _debts = debtMaps.map((map) => Debt.fromMap(map)).toList();

      // Load Credits
      final List<Map<String, dynamic>> creditMaps = await db.query('credits', orderBy: 'date DESC');
      _credits = creditMaps.map((map) => Credit.fromMap(map)).toList();

    } catch (e) {
      debugPrint("Error loading local SQLite data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // ACCOUNT OPERATIONS
  // ==========================================
  Future<void> addAccount(Account account) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('accounts', account.toMap());
    await loadAllData();
  }

  Future<void> updateAccount(Account account) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
    await loadAllData();
  }

  Future<void> archiveAccount(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'accounts',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadAllData();
  }

  Future<void> unarchiveAccount(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'accounts',
      {'isArchived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadAllData();
  }

  Future<void> deleteAccount(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
      await txn.delete('records', where: 'accountId = ? OR fromAccountId = ? OR toAccountId = ?', whereArgs: [id, id, id]);
    });
    await loadAllData();
  }

  // ==========================================
  // TRANSACTION (RECORD) OPERATIONS
  // ==========================================
  Future<void> addRecord(Record record) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Insert record
      await txn.insert('records', record.toMap());

      // 2. Adjust account balances
      if (record.type == 'expense') {
        await _adjustBalance(txn, record.accountId, -record.amount);
      } else if (record.type == 'income') {
        await _adjustBalance(txn, record.accountId, record.amount);
      } else if (record.type == 'transfer') {
        if (record.fromAccountId != null) {
          await _adjustBalance(txn, record.fromAccountId!, -record.amount);
        }
        if (record.toAccountId != null) {
          await _adjustBalance(txn, record.toAccountId!, record.amount);
        }
      }
    });
    await loadAllData();
  }

  Future<void> deleteRecord(Record record) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Delete record
      await txn.delete('records', where: 'id = ?', whereArgs: [record.id]);

      // 2. Revert account balances (opposite of add)
      if (record.type == 'expense') {
        await _adjustBalance(txn, record.accountId, record.amount);
      } else if (record.type == 'income') {
        await _adjustBalance(txn, record.accountId, -record.amount);
      } else if (record.type == 'transfer') {
        if (record.fromAccountId != null) {
          await _adjustBalance(txn, record.fromAccountId!, record.amount);
        }
        if (record.toAccountId != null) {
          await _adjustBalance(txn, record.toAccountId!, -record.amount);
        }
      }
    });
    await loadAllData();
  }

  Future<void> updateRecord(Record oldRecord, Record newRecord) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Revert old balances
      if (oldRecord.type == 'expense') {
        await _adjustBalance(txn, oldRecord.accountId, oldRecord.amount);
      } else if (oldRecord.type == 'income') {
        await _adjustBalance(txn, oldRecord.accountId, -oldRecord.amount);
      } else if (oldRecord.type == 'transfer') {
        if (oldRecord.fromAccountId != null) {
          await _adjustBalance(txn, oldRecord.fromAccountId!, oldRecord.amount);
        }
        if (oldRecord.toAccountId != null) {
          await _adjustBalance(txn, oldRecord.toAccountId!, -oldRecord.amount);
        }
      }

      // 2. Update record
      await txn.update(
        'records',
        newRecord.toMap(),
        where: 'id = ?',
        whereArgs: [newRecord.id],
      );

      // 3. Apply new balances
      if (newRecord.type == 'expense') {
        await _adjustBalance(txn, newRecord.accountId, -newRecord.amount);
      } else if (newRecord.type == 'income') {
        await _adjustBalance(txn, newRecord.accountId, newRecord.amount);
      } else if (newRecord.type == 'transfer') {
        if (newRecord.fromAccountId != null) {
          await _adjustBalance(txn, newRecord.fromAccountId!, -newRecord.amount);
        }
        if (newRecord.toAccountId != null) {
          await _adjustBalance(txn, newRecord.toAccountId!, newRecord.amount);
        }
      }
    });
    await loadAllData();
  }

  Future<void> _adjustBalance(Transaction txn, String accountId, double adjustment) async {
    final List<Map<String, dynamic>> res = await txn.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
    );
    if (res.isNotEmpty) {
      final currentBalance = (res.first['balance'] as num).toDouble();
      final newBalance = currentBalance + adjustment;
      await txn.update(
        'accounts',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
  }

  // ==========================================
  // CATEGORY OPERATIONS
  // ==========================================
  Future<void> addCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', category.toMap());
    await loadAllData();
  }

  Future<void> archiveCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'categories',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadAllData();
  }

  // ==========================================
  // TEMPLATES OPERATIONS
  // ==========================================
  Future<void> addTemplate(Template template) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('templates', template.toMap());
    await loadAllData();
  }

  Future<void> deleteTemplate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
    await loadAllData();
  }

  // ==========================================
  // PLANNED PAYMENTS OPERATIONS
  // ==========================================
  Future<void> addPlannedPayment(PlannedPayment payment) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('planned_payments', payment.toMap());
    await loadAllData();
  }

  Future<void> deletePlannedPayment(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('planned_payments', where: 'id = ?', whereArgs: [id]);
    await loadAllData();
  }

  Future<void> triggerPlannedPayment(PlannedPayment payment) async {
    final recordId = uuid.v4();
    final newRecord = Record(
      id: recordId,
      type: 'expense',
      amount: payment.amount,
      currency: payment.currency,
      accountId: payment.accountId,
      categoryId: payment.categoryId,
      note: 'Triggered planned payment: ${payment.name}. ${payment.notes ?? ""}',
      dateTime: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await addRecord(newRecord);
    // If one-time, delete it. If recurring, we keep it but it logs history
    if (payment.frequency == 'one-time') {
      await deletePlannedPayment(payment.id);
    }
  }

  // ==========================================
  // DEBTS OPERATIONS (I LENT)
  // ==========================================
  Future<void> addDebt(Debt debt, {String? categoryId}) async {
    final db = await DatabaseHelper.instance.database;
    
    // Auto-create companion Record (type: expense)
    final recordId = debt.recordId;
    final companionRecord = Record(
      id: recordId,
      type: 'expense',
      amount: debt.amount,
      currency: 'INR',
      accountId: debt.accountId,
      categoryId: categoryId,
      note: 'Lent money to ${debt.borrowerName}. ${debt.notes ?? ""}',
      dateTime: debt.date,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      // 1. Insert debt
      await txn.insert('debts', debt.toMap());
      // 2. Insert companion record
      await txn.insert('records', companionRecord.toMap());
      // 3. Deduct from account balance
      await _adjustBalance(txn, debt.accountId, -debt.amount);
    });

    await loadAllData();
  }

  Future<void> markDebtAsPaid(String debtId, String receivingAccountId) async {
    final db = await DatabaseHelper.instance.database;
    
    final List<Map<String, dynamic>> res = await db.query('debts', where: 'id = ?', whereArgs: [debtId]);
    if (res.isEmpty) return;
    
    final debt = Debt.fromMap(res.first);
    if (debt.isPaid) return;

    final paidRecordId = uuid.v4();
    final recoveryRecord = Record(
      id: paidRecordId,
      type: 'income',
      amount: debt.amount,
      currency: 'INR',
      accountId: receivingAccountId,
      note: 'Debt paid back by ${debt.borrowerName}',
      dateTime: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      // 1. Update debt state
      await txn.update(
        'debts',
        {
          'isPaid': 1,
          'paidToAccountId': receivingAccountId,
          'paidRecordId': paidRecordId,
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );
      // 2. Insert recovery record
      await txn.insert('records', recoveryRecord.toMap());
      // 3. Add to account balance
      await _adjustBalance(txn, receivingAccountId, debt.amount);
    });

    await loadAllData();
  }

  // ==========================================
  // CREDITS OPERATIONS (I BORROWED)
  // ==========================================
  Future<void> addCredit(Credit credit, {String? categoryId}) async {
    final db = await DatabaseHelper.instance.database;
    
    // Auto-create companion Record (type: income)
    final recordId = credit.recordId;
    final companionRecord = Record(
      id: recordId,
      type: 'income',
      amount: credit.amount,
      currency: 'INR',
      accountId: credit.accountId,
      categoryId: categoryId,
      note: 'Borrowed money from ${credit.lenderName}. ${credit.notes ?? ""}',
      dateTime: credit.date,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      // 1. Insert credit
      await txn.insert('credits', credit.toMap());
      // 2. Insert companion record
      await txn.insert('records', companionRecord.toMap());
      // 3. Add to account balance
      await _adjustBalance(txn, credit.accountId, credit.amount);
    });

    await loadAllData();
  }

  Future<void> markCreditAsPaid(String creditId, String payingAccountId) async {
    final db = await DatabaseHelper.instance.database;
    
    final List<Map<String, dynamic>> res = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
    if (res.isEmpty) return;
    
    final credit = Credit.fromMap(res.first);
    if (credit.isPaid) return;

    final paidRecordId = uuid.v4();
    final paybackRecord = Record(
      id: paidRecordId,
      type: 'expense',
      amount: credit.amount,
      currency: 'INR',
      accountId: payingAccountId,
      note: 'Repaid credit borrowed from ${credit.lenderName}',
      dateTime: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      // 1. Update credit state
      await txn.update(
        'credits',
        {
          'isPaid': 1,
          'paidFromAccountId': payingAccountId,
          'paidRecordId': paidRecordId,
        },
        where: 'id = ?',
        whereArgs: [creditId],
      );
      // 2. Insert payback record
      await txn.insert('records', paybackRecord.toMap());
      // 3. Deduct from account balance
      await _adjustBalance(txn, payingAccountId, -credit.amount);
    });

    await loadAllData();
  }

  // ==========================================
  // EXPORT/IMPORT SERIALIZATION SERVICES
  // ==========================================
  Future<Map<String, dynamic>> exportDatabaseAsJson() async {
    final db = await DatabaseHelper.instance.database;
    
    final accountsList = await db.query('accounts');
    final recordsList = await db.query('records');
    final categoriesList = await db.query('categories');
    final templatesList = await db.query('templates');
    final plannedList = await db.query('planned_payments');
    final debtsList = await db.query('debts');
    final creditsList = await db.query('credits');

    return {
      'accounts': accountsList,
      'records': recordsList,
      'categories': categoriesList,
      'templates': templatesList,
      'planned_payments': plannedList,
      'debts': debtsList,
      'credits': creditsList,
    };
  }

  Future<void> importDatabaseFromJson(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.transaction((txn) async {
      // Clean tables
      await txn.delete('accounts');
      await txn.delete('records');
      await txn.delete('categories');
      await txn.delete('templates');
      await txn.delete('planned_payments');
      await txn.delete('debts');
      await txn.delete('credits');

      // Re-populate accounts
      if (data.containsKey('accounts')) {
        for (var row in data['accounts'] as List) {
          await txn.insert('accounts', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate categories
      if (data.containsKey('categories')) {
        for (var row in data['categories'] as List) {
          await txn.insert('categories', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate records
      if (data.containsKey('records')) {
        for (var row in data['records'] as List) {
          await txn.insert('records', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate templates
      if (data.containsKey('templates')) {
        for (var row in data['templates'] as List) {
          await txn.insert('templates', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate planned payments
      if (data.containsKey('planned_payments')) {
        for (var row in data['planned_payments'] as List) {
          await txn.insert('planned_payments', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate debts
      if (data.containsKey('debts')) {
        for (var row in data['debts'] as List) {
          await txn.insert('debts', Map<String, dynamic>.from(row));
        }
      }

      // Re-populate credits
      if (data.containsKey('credits')) {
        for (var row in data['credits'] as List) {
          await txn.insert('credits', Map<String, dynamic>.from(row));
        }
      }
    });

    await loadAllData();
  }

  // ==========================================
  // EXCEL / CSV BATCH IMPORTER
  // ==========================================
  Future<void> importParsedRecords(List<Map<String, dynamic>> importedList) async {
    if (importedList.isEmpty) return;

    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (var imp in importedList) {
        final String accountName = imp['account'];
        final String? categoryName = imp['category'];
        
        // Find or create account
        String accountId = '';
        final List<Map<String, dynamic>> accMatch = await txn.query(
          'accounts',
          where: 'LOWER(name) = ?',
          whereArgs: [accountName.toLowerCase()],
        );
        if (accMatch.isNotEmpty) {
          accountId = accMatch.first['id'];
        } else {
          accountId = uuid.v4();
          final newAcc = Account(
            id: accountId,
            name: accountName,
            currency: imp['currency'] ?? 'INR',
            color: '0xFF2196F3',
            balance: 0.0,
            isArchived: false,
            createdAt: DateTime.now(),
          );
          await txn.insert('accounts', newAcc.toMap());
        }

        // Find or create category
        String? categoryId;
        if (categoryName != null && categoryName.trim().isNotEmpty) {
          final List<Map<String, dynamic>> catMatch = await txn.query(
            'categories',
            where: 'LOWER(name) = ?',
            whereArgs: [categoryName.toLowerCase()],
          );
          if (catMatch.isNotEmpty) {
            categoryId = catMatch.first['id'];
          } else {
            categoryId = uuid.v4();
            final newCat = Category(
              id: categoryId,
              name: categoryName,
              color: '0xFF9E9E9E',
              icon: 'category',
              isArchived: false,
            );
            await txn.insert('categories', newCat.toMap());
          }
        }

        // Handle Transfer Account mapping
        String? fromAccId;
        String? toAccId;
        if (imp['type'] == 'transfer') {
          final String? fromName = imp['fromAccount'];
          final String? toName = imp['toAccount'];

          if (fromName != null && fromName.isNotEmpty) {
            final List<Map<String, dynamic>> fromMatch = await txn.query(
              'accounts',
              where: 'LOWER(name) = ?',
              whereArgs: [fromName.toLowerCase()],
            );
            if (fromMatch.isNotEmpty) {
              fromAccId = fromMatch.first['id'];
            }
          }
          if (toName != null && toName.isNotEmpty) {
            final List<Map<String, dynamic>> toMatch = await txn.query(
              'accounts',
              where: 'LOWER(name) = ?',
              whereArgs: [toName.toLowerCase()],
            );
            if (toMatch.isNotEmpty) {
              toAccId = toMatch.first['id'];
            }
          }
        }

        // Insert Record
        final double amt = imp['amount'];
        final DateTime recordDate = DateTime.tryParse(imp['date']) ?? DateTime.now();
        final recordId = uuid.v4();

        final Record rec = Record(
          id: recordId,
          type: imp['type'],
          amount: amt,
          currency: imp['currency'] ?? 'INR',
          accountId: accountId,
          fromAccountId: fromAccId,
          toAccountId: toAccId,
          categoryId: categoryId,
          note: imp['note'],
          dateTime: recordDate,
          createdAt: DateTime.now(),
        );

        await txn.insert('records', rec.toMap());

        // Balance adjustments
        if (rec.type == 'expense') {
          await _adjustBalance(txn, accountId, -amt);
        } else if (rec.type == 'income') {
          await _adjustBalance(txn, accountId, amt);
        } else if (rec.type == 'transfer') {
          if (fromAccId != null) {
            await _adjustBalance(txn, fromAccId, -amt);
          }
          if (toAccId != null) {
            await _adjustBalance(txn, toAccId, amt);
          }
        }
      }
    });

    await loadAllData();
  }
}
