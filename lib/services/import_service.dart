import 'dart:convert';
import 'package:excel/excel.dart';

class ImportService {
  static final ImportService instance = ImportService._init();

  ImportService._init();

  /// Parses CSV raw text into standard map structure
  List<Map<String, dynamic>> parseCSV(String csvContent) {
    final List<Map<String, dynamic>> records = [];
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    // Parse header
    final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      
      final Map<String, dynamic> record = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < values.length) {
          record[headers[j]] = values[j];
        }
      }
      
      if (_isValidImportRecord(record)) {
        records.add(_sanitizeImportRecord(record));
      }
    }
    return records;
  }

  /// Parses an Excel sheet from bytes
  List<Map<String, dynamic>> parseExcel(List<int> bytes) {
    final List<Map<String, dynamic>> records = [];
    final excel = Excel.decodeBytes(bytes);
    
    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      // Extract headers from first row
      final headers = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
          .toList();

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> record = {};
        
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length && headers[j].isNotEmpty) {
            record[headers[j]] = row[j]?.value?.toString().trim() ?? '';
          }
        }
        
        if (_isValidImportRecord(record)) {
          records.add(_sanitizeImportRecord(record));
        }
      }
      break; // Only parse first sheet
    }
    return records;
  }

  bool _isValidImportRecord(Map<String, dynamic> record) {
    return record.containsKey('date') &&
        record.containsKey('type') &&
        record.containsKey('amount') &&
        record.containsKey('currency') &&
        record.containsKey('account');
  }

  Map<String, dynamic> _sanitizeImportRecord(Map<String, dynamic> record) {
    final type = record['type'].toString().toLowerCase().trim();
    return {
      'date': record['date'].toString(),
      'type': (type == 'expense' || type == 'income' || type == 'transfer') ? type : 'expense',
      'amount': double.tryParse(record['amount'].toString()) ?? 0.0,
      'currency': record['currency'].toString().toUpperCase(),
      'account': record['account'].toString(),
      'category': record['category']?.toString(),
      'note': record['note']?.toString(),
      'fromAccount': record['fromaccount']?.toString() ?? record['fromAccount']?.toString(),
      'toAccount': record['toaccount']?.toString() ?? record['toAccount']?.toString(),
    };
  }
}
