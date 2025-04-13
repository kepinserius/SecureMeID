import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();

  // AES encryption (for symmetric encryption)
  String encryptData(String plainText, String passphrase) {
    try {
      // Generate a key from the passphrase
      final key = _generateKeyFromPassphrase(passphrase);
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return the encrypted text and IV as a combined string
      return '${encrypted.base64}|${iv.base64}';
    } catch (e) {
      rethrow;
    }
  }

  // AES decryption (for symmetric decryption)
  String decryptData(String encryptedText, String passphrase) {
    try {
      // Split the encrypted text and IV
      final parts = encryptedText.split('|');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final encryptedData = parts[0];
      final ivData = parts[1];

      // Generate key from passphrase
      final key = _generateKeyFromPassphrase(passphrase);
      final iv = encrypt.IV.fromBase64(ivData);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);

      return decrypted;
    } catch (e) {
      rethrow;
    }
  }

  // Generate a key from a passphrase
  encrypt.Key _generateKeyFromPassphrase(String passphrase) {
    // Use SHA-256 to generate a consistent key from the passphrase
    final hash = sha256.convert(utf8.encode(passphrase));
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Store a key securely
  Future<void> storeSecureKey(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // Retrieve a key securely
  Future<String?> getSecureKey(String key) async {
    return await _secureStorage.read(key: key);
  }

  // Delete a key securely
  Future<void> deleteSecureKey(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Hash data for verification
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate a secure random string
  String generateSecureRandomString(int length) {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
