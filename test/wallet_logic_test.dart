import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/models/account.dart';
import 'package:my_wallet/models/record.dart';
import 'package:my_wallet/models/category.dart';
import 'package:my_wallet/services/encryption_service.dart';

void main() {
  group('MyWallet Data Models & Serialization Tests', () {
    test('Account serialization matches the specification', () {
      final now = DateTime.now();
      final account = Account(
        id: 'acc-123',
        name: 'SBI Savings',
        accountNumber: '987654321',
        currency: 'INR',
        color: '0xFF2196F3',
        balance: 15000.50,
        isArchived: false,
        createdAt: now,
      );

      final map = account.toMap();
      expect(map['id'], 'acc-123');
      expect(map['balance'], 15000.50);
      expect(map['isArchived'], 0); // Boolean saved as int in SQLite
      expect(map['createdAt'], now.toIso8601String());

      final deserialized = Account.fromMap(map);
      expect(deserialized.id, 'acc-123');
      expect(deserialized.balance, 15000.50);
      expect(deserialized.isArchived, false);
      expect(deserialized.createdAt.year, now.year);
    });

    test('Record serialization matches the specification', () {
      final now = DateTime.now();
      final record = Record(
        id: 'rec-999',
        type: 'expense',
        amount: 250.75,
        currency: 'INR',
        accountId: 'acc-123',
        categoryId: 'cat-444',
        note: 'Dinner',
        dateTime: now,
        createdAt: now,
      );

      final map = record.toMap();
      expect(map['id'], 'rec-999');
      expect(map['amount'], 250.75);
      expect(map['note'], 'Dinner');

      final deserialized = Record.fromMap(map);
      expect(deserialized.id, 'rec-999');
      expect(deserialized.amount, 250.75);
      expect(deserialized.note, 'Dinner');
    });
  });

  group('AES-256 Cryptographic Backup Tests', () {
    test('Encryption & Decryption returns exact matches and zero data leaks', () {
      final secretKey = 'google-oauth-uid-example-12345';
      final Map<String, dynamic> dbPayload = {
        'accounts': [
          {'id': 'acc-1', 'name': 'Cash Wallet', 'balance': 500.0}
        ],
        'records': [
          {'id': 'rec-1', 'type': 'expense', 'amount': 150.0}
        ],
      };

      // 1. Encrypt payload
      final String ciphertext = EncryptionService.encrypt(dbPayload, secretKey);
      expect(ciphertext, isNotEmpty);
      expect(ciphertext.contains('Cash Wallet'), isFalse); // Data is fully scrambled
      expect(ciphertext.contains('rec-1'), isFalse);

      // 2. Decrypt payload
      final Map<String, dynamic> decrypted = EncryptionService.decrypt(ciphertext, secretKey);
      expect(decrypted, isNotEmpty);
      expect(decrypted['accounts'][0]['name'], 'Cash Wallet');
      expect(decrypted['records'][0]['amount'], 150.0);
    });
  });

  group('AI Transaction Parsing Schema Tests', () {
    test('Simulated Gemini response correctly maps to Record attributes', () {
      final simulatedResult = {
        'amount': 450.0,
        'type': 'expense',
        'note': 'train ticket',
        'dateTime': '2026-06-06T21:45:00.000Z',
        'accountName': 'SBI Savings',
        'categoryName': 'Travel'
      };

      final dummyAccounts = [
        Account(
          id: 'acc-123',
          name: 'SBI Savings',
          currency: 'INR',
          color: '0xFF2196F3',
          balance: 10000,
          isArchived: false,
          createdAt: DateTime.now(),
        )
      ];
      final dummyCategories = [
        Category(
          id: 'cat-456',
          name: 'Travel',
          color: '0xFF9E9E9E',
          icon: 'flight',
          isArchived: false,
        )
      ];

      String? matchedAccountId;
      for (var acc in dummyAccounts) {
        if (acc.name.toLowerCase() == simulatedResult['accountName'].toString().toLowerCase()) {
          matchedAccountId = acc.id;
          break;
        }
      }

      String? matchedCategoryId;
      for (var cat in dummyCategories) {
        if (cat.name.toLowerCase() == simulatedResult['categoryName'].toString().toLowerCase()) {
          matchedCategoryId = cat.id;
          break;
        }
      }

      final record = Record(
        id: 'rec-ai-1',
        type: simulatedResult['type'] as String,
        amount: simulatedResult['amount'] as double,
        currency: 'INR',
        accountId: matchedAccountId!,
        categoryId: matchedCategoryId,
        note: simulatedResult['note'] as String,
        dateTime: DateTime.parse(simulatedResult['dateTime'] as String),
        createdAt: DateTime.now(),
      );

      expect(record.accountId, 'acc-123');
      expect(record.categoryId, 'cat-456');
      expect(record.amount, 450.0);
      expect(record.type, 'expense');
      expect(record.note, 'train ticket');
      expect(record.dateTime.year, 2026);
      expect(record.dateTime.month, 6);
      expect(record.dateTime.day, 6);
    });
  });
}
