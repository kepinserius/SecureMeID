import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pointycastle;

/// Enhanced encryption service with advanced security features
class EncryptionService extends ChangeNotifier {
  // Use secure storage with enhanced security options
  final _secureStorage = const FlutterSecureStorage();

  // PBKDF2 key derivation parameters
  static const int _pbkdf2Iterations = 100000; // Recommended minimum iterations
  static const int _saltBytes = 32;
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  // AES encryption with enhanced security
  Future<String> encryptData(String plainText, String passphrase) async {
    try {
      // Generate a random salt
      final salt = _generateSecureRandomBytes(_saltBytes);

      // Derive key using PBKDF2 (more secure than simple hashing)
      final key = await _deriveKeyFromPassphrase(passphrase, salt);

      // Generate a random IV
      final iv = encrypt.IV(_generateSecureRandomBytes(_ivLength));

      // Encrypt using AES-CBC mode (supported by the encrypt package)
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Combine salt, IV, and encrypted data with version marker for future compatibility
      final saltBase64 = base64Encode(salt);

      // Version 2 format: v2:salt:iv:encryptedData
      return 'v2:$saltBase64:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  // AES decryption with enhanced security
  Future<String> decryptData(String encryptedText, String passphrase) async {
    try {
      // Split the encrypted components
      final parts = encryptedText.split(':');

      // Handle different format versions
      if (parts.length == 4 && parts[0] == 'v2') {
        // V2 format with better key derivation
        final salt = base64Decode(parts[1]);
        final ivData = parts[2];
        final encryptedData = parts[3];

        // Derive key from passphrase and salt
        final key = await _deriveKeyFromPassphrase(passphrase, salt);
        final iv = encrypt.IV.fromBase64(ivData);

        // Decrypt with the enhanced key
        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        return encrypter.decrypt64(encryptedData, iv: iv);
      } else if (encryptedText.contains('|')) {
        // Legacy format (maintain backward compatibility)
        final legacyParts = encryptedText.split('|');
        if (legacyParts.length != 2) {
          throw Exception('Invalid encrypted data format');
        }

        final encryptedData = legacyParts[0];
        final ivData = legacyParts[1];

        // Generate key from passphrase using old method
        final key = _generateLegacyKeyFromPassphrase(passphrase);
        final iv = encrypt.IV.fromBase64(ivData);

        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        return encrypter.decrypt64(encryptedData, iv: iv);
      } else {
        throw Exception('Invalid encrypted data format');
      }
    } catch (e) {
      // Use generic error message to prevent revealing too much information
      throw Exception('Decryption failed: authentication failed');
    }
  }

  // Derive a key from a passphrase using PBKDF2 (more secure than simple hashing)
  Future<encrypt.Key> _deriveKeyFromPassphrase(
      String passphrase, Uint8List salt) async {
    try {
      final pbkdf2Params = pointycastle.Pbkdf2Parameters(
        salt,
        _pbkdf2Iterations,
        _keyLength,
      );

      final pbkdf2 = pointycastle.PBKDF2KeyDerivator(
          pointycastle.HMac(pointycastle.SHA256Digest(), 64));
      pbkdf2.init(pbkdf2Params);

      final derivedKey =
          pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
      return encrypt.Key(derivedKey);
    } catch (e) {
      throw Exception('Key derivation failed: ${e.toString()}');
    }
  }

  // Legacy key derivation method (for backward compatibility)
  encrypt.Key _generateLegacyKeyFromPassphrase(String passphrase) {
    final hash = sha256.convert(utf8.encode(passphrase));
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Generate cryptographically secure random bytes
  Uint8List _generateSecureRandomBytes(int length) {
    final secureRandom = pointycastle.SecureRandom('Fortuna')
      ..seed(pointycastle.KeyParameter(
        Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)),
        ),
      ));
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = secureRandom.nextUint8();
    }
    return bytes;
  }

  // Store a key securely
  Future<void> storeSecureKey(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Failed to store secure key: ${e.toString()}');
    }
  }

  // Retrieve a key securely
  Future<String?> getSecureKey(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception('Failed to retrieve secure key: ${e.toString()}');
    }
  }

  // Delete a key securely
  Future<void> deleteSecureKey(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete secure key: ${e.toString()}');
    }
  }

  // Hash data for verification with constant-time comparison
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Compare hashes in constant time to prevent timing attacks
  bool compareHashes(String hash1, String hash2) {
    if (hash1.length != hash2.length) return false;

    int result = 0;
    for (int i = 0; i < hash1.length; i++) {
      result |= hash1.codeUnitAt(i) ^ hash2.codeUnitAt(i);
    }
    return result == 0;
  }

  // Generate a secure random token/string
  String generateSecureRandomString(int length) {
    final random = Random.secure();
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final values =
        List<int>.generate(length, (_) => random.nextInt(charset.length));
    return String.fromCharCodes(values.map((i) => charset.codeUnitAt(i)));
  }
}
