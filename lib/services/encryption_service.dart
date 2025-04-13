import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/pointycastle.dart' as pointy;

class EncryptionService extends ChangeNotifier {
  // AES encryption (for symmetric encryption)
  String encrypt(String plainText, String passphrase) {
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
  String decrypt(String encryptedText, String passphrase) {
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
  
  // Generate RSA key pair for asymmetric encryption
  Map<String, String> generateRSAKeyPair() {
    try {
      // Create a secure random number generator
      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = <int>[];
      for (var i = 0; i < 32; i++) {
        seeds.add(seedSource.nextInt(255));
      }
      secureRandom.seed(pointy.KeyParameter(Uint8List.fromList(seeds)));
      
      // Create a key generator
      final keyGen = RSAKeyGenerator()
        ..init(pointy.ParametersWithRandom(
          pointy.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          secureRandom,
        ));
      
      // Generate the key pair
      final pair = keyGen.generateKeyPair();
      final publicKey = pair.publicKey as RSAPublicKey;
      final privateKey = pair.privateKey as RSAPrivateKey;
      
      // Convert keys to PEM format
      final publicKeyPem = _rsaPublicKeyToPem(publicKey);
      final privateKeyPem = _rsaPrivateKeyToPem(privateKey);
      
      return {
        'publicKey': publicKeyPem,
        'privateKey': privateKeyPem,
      };
    } catch (e) {
      rethrow;
    }
  }
  
  // RSA encryption (for asymmetric encryption)
  String encryptWithRSA(String plainText, String publicKeyPem) {
    try {
      final publicKey = _rsaPemToPublicKey(publicKeyPem);
      final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(plainText);
      return encrypted.base64;
    } catch (e) {
      rethrow;
    }
  }
  
  // RSA decryption (for asymmetric decryption)
  String decryptWithRSA(String encryptedText, String privateKeyPem) {
    try {
      final privateKey = _rsaPemToPrivateKey(privateKeyPem);
      final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
      final decrypted = encrypter.decrypt64(encryptedText);
      return decrypted;
    } catch (e) {
      rethrow;
    }
  }
  
  // Convert RSA private key to PEM format
  String _rsaPrivateKeyToPem(RSAPrivateKey privateKey) {
    final rsaPrivateKey = encrypt.RSAPrivateKey(
      privateKey.modulus!,
      privateKey.privateExponent!,
      privateKey.p,
      privateKey.q,
    );
    return rsaPrivateKey.toPEM();
  }
  
  // Convert RSA public key to PEM format
  String _rsaPublicKeyToPem(RSAPublicKey publicKey) {
    final rsaPublicKey = encrypt.RSAPublicKey(
      publicKey.modulus!,
      publicKey.exponent!,
    );
    return rsaPublicKey.toPEM();
  }
  
  // Convert PEM to RSA private key
  encrypt.RSAPrivateKey _rsaPemToPrivateKey(String privateKeyPem) {
    return encrypt.RSAKeyParser().parse(privateKeyPem) as encrypt.RSAPrivateKey;
  }
  
  // Convert PEM to RSA public key
  encrypt.RSAPublicKey _rsaPemToPublicKey(String publicKeyPem) {
    return encrypt.RSAKeyParser().parse(publicKeyPem) as encrypt.RSAPublicKey;
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
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
} 