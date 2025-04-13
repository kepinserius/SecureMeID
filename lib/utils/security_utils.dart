import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Security utilities for enhanced app protection
class SecurityUtils {
  // Singleton instance
  static final SecurityUtils _instance = SecurityUtils._internal();

  // Secure storage instance with platform-specific options
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  // Private constructor
  SecurityUtils._internal();

  // Factory constructor to access singleton
  factory SecurityUtils() => _instance;

  /// Checks for signs of a compromised environment (rooted/jailbroken device)
  Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false; // Web platform doesn't apply

    if (Platform.isAndroid) {
      return await _isAndroidRooted();
    } else if (Platform.isIOS) {
      return await _isIosJailbroken();
    }

    return false;
  }

  /// Detects root on Android devices through file checks
  Future<bool> _isAndroidRooted() async {
    // Check for common root management apps
    final suPaths = [
      '/system/app/Superuser.apk',
      '/system/xbin/su',
      '/system/bin/su',
      '/sbin/su',
      '/system/su',
      '/system/bin/.ext/.su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
    ];

    try {
      // Check for su binary (superuser) and other root indicators
      for (final path in suPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Additional checks could be added here
      return false;
    } catch (e) {
      // If permissions are restricted, we'll get errors on these checks
      return false;
    }
  }

  /// Detects jailbreak on iOS devices through file checks
  Future<bool> _isIosJailbroken() async {
    // Check for common jailbreak signs
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/usr/bin/ssh',
    ];

    try {
      // Check for Cydia and other jailbreak indicators
      for (final path in jailbreakPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Check if app can write to system locations
      final testPath =
          '/private/jailbreak_test_${DateTime.now().microsecondsSinceEpoch}.txt';
      try {
        await File(testPath).writeAsString('jailbreak_test', flush: true);
        await File(testPath).delete();
        return true; // App should not be able to write here
      } catch (_) {
        // Expected to fail on non-jailbroken device
      }

      return false;
    } catch (e) {
      // If permissions are restricted, we'll get errors on these checks
      return false;
    }
  }

  /// Simple placeholder for app tampering detection
  /// In a real app, you would use package_info_plus to check signatures
  bool isAppTampered() {
    // Simplified implementation
    // For actual implementation, add package_info_plus dependency
    // and check app signature against known good values
    return false;
  }

  /// Securely store sensitive data
  Future<void> secureWrite(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Securely retrieve sensitive data
  Future<String?> secureRead(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Securely delete sensitive data
  Future<void> secureDelete(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Delete all secure data (during logout or detected compromise)
  Future<void> secureWipeAll() async {
    await _secureStorage.deleteAll();
  }

  /// Generate secure random challenge for server auth
  String generateChallenge(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}

/// A secure HTTP client implementation
/// This is a basic implementation - in a production app, you would:
/// 1. Implement certificate pinning manually
/// 2. Add request/response interceptors for security headers
/// 3. Validate all responses for potential security issues
class SecureHttpClient {
  final http.Client _client = http.Client();
  final String _baseUrl;

  SecureHttpClient(this._baseUrl);

  /// Performs a secure GET request
  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final url = Uri.parse('$_baseUrl/$path');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-Security-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?headers,
    };

    return await _client.get(url, headers: requestHeaders);
  }

  /// Performs a secure POST request
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$_baseUrl/$path');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-Security-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?headers,
    };

    return await _client.post(url, headers: requestHeaders, body: body);
  }

  /// Closes the client
  void close() {
    _client.close();
  }
}
