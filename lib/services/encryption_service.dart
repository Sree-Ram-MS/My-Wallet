import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // Secret salt for extra layer of cryptographic protection
  static const String _defaultSalt = "MY_WALLET_SECURE_SALT_9876543210";

  /// Derives a 32-byte key from the combined userId and salt
  static Key _deriveKey(String secretKey, String salt) {
    final combined = utf8.encode("$secretKey$salt");
    final hash = sha256.convert(combined);
    return Key(Uint8List.fromList(hash.bytes));
  }

  /// Derives a 16-byte IV (Initialization Vector) from the secretKey
  static IV _deriveIV(String secretKey) {
    final hash = md5.convert(utf8.encode(secretKey));
    return IV(Uint8List.fromList(hash.bytes));
  }

  /// Encrypts an object (converted to JSON string) with AES-256
  static String encrypt(Map<String, dynamic> data, String secretKey, {String salt = _defaultSalt}) {
    try {
      final plaintext = json.encode(data);
      final key = _deriveKey(secretKey, salt);
      final iv = _deriveIV(secretKey);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return encrypted.base64;
    } catch (e) {
      rethrow;
    }
  }

  /// Decrypts an AES-256 base64 ciphertext back into a Map
  static Map<String, dynamic> decrypt(String cipherText, String secretKey, {String salt = _defaultSalt}) {
    try {
      final key = _deriveKey(secretKey, salt);
      final iv = _deriveIV(secretKey);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt(Encrypted.fromBase64(cipherText), iv: iv);
      return json.decode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
