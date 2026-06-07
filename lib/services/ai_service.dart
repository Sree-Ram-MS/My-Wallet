import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  /// Parses a natural language prompt into transaction structure using Google Gemini REST API (gemini-2.5-flash).
  static Future<Map<String, dynamic>?> parseTransaction({
    required String apiKey,
    required String prompt,
    required DateTime currentDateTime,
    required List<String> accounts,
    required List<String> categories,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    final systemInstruction = '''
You are a financial transaction parsing assistant. Your task is to extract transaction details from the user's natural language input and output a single JSON object.

Current date/time:
${currentDateTime.toIso8601String()} (Local time: ${currentDateTime.toString()})

Available Accounts:
${accounts.map((a) => "- $a").join('\n')}

Available Categories:
${categories.map((c) => "- $c").join('\n')}

Rules for parsing:
1. Extract the 'amount' as a positive double.
2. Determine 'type' of transaction: 'expense', 'income', or 'transfer'.
3. Extract 'note' describing the transaction (e.g. "Train ticket", "Salary credit"). Keep it concise.
4. Determine 'dateTime' (in ISO 8601 format). Calculate it relative to the current date/time context. If no time is specified, use the current date/time.
5. Map 'accountName' to one of the Available Accounts. Choose the best matching account. If none fits or is specified, default to the first available account in the list.
6. Map 'categoryName' to one of the Available Categories. Choose the best matching category. If none fits or is specified, output null.
7. For transfer type, extract 'fromAccountName' (source) and 'toAccountName' (destination).

Output format must be valid JSON matching this exact structure:
{
  "amount": double,
  "type": "expense" | "income" | "transfer",
  "note": string,
  "dateTime": "YYYY-MM-DDTHH:MM:SS.SSSZ",
  "accountName": string,
  "categoryName": string or null,
  "fromAccountName": string or null,
  "toAccountName": string or null
}
''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final contentText = candidates[0]['content']?['parts']?[0]?['text'] as String?;
          if (contentText != null) {
            debugPrint("Gemini response text: $contentText");
            return json.decode(contentText.trim()) as Map<String, dynamic>;
          }
        }
        throw Exception("Empty content or unexpected structure in Gemini response.");
      } else {
        try {
          final errorBody = json.decode(response.body);
          final errorMessage = errorBody['error']?['message'] ?? response.body;
          throw Exception("Gemini API Error: $errorMessage");
        } catch (_) {
          throw Exception("Gemini API Error (${response.statusCode}): ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("Gemini transaction parsing error: $e");
      rethrow;
    }
  }
}
