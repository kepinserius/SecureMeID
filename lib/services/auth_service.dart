import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:web3dart/web3dart.dart';
import 'package:uuid/uuid.dart';
import 'package:secureme_id/services/encryption_service.dart';

class AuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final EncryptionService _encryptionService = EncryptionService();
  final _userBox = Hive.box('userCredentials');
  
  String? _userId;
  String? _userWalletAddress;
  String? _userPublicKey;
  bool _isLoggedIn = false;
  
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get walletAddress => _userWalletAddress;
  String? get publicKey => _userPublicKey;
  
  // Check if biometrics are available
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  // Check if user is already logged in
  bool isUserLoggedIn() {
    final hasUserId = _userBox.containsKey('userId');
    return hasUserId;
  }
  
  // Generate entropy from biometric data and user input
  Future<String> _generateEntropy(String pin, String salt) async {
    final pinHash = sha256.convert(utf8.encode(pin + salt)).toString();
    return pinHash;
  }
  
  // Generate a new wallet for the user
  Future<Map<String, String>> generateWallet(String pin) async {
    // Generate a random salt
    final salt = const Uuid().v4();
    
    // Generate entropy from PIN and salt
    final entropy = await _generateEntropy(pin, salt);
    
    // Generate mnemonic from entropy
    final mnemonic = bip39.generateMnemonic(strength: 256);
    
    // Derive the seed from the mnemonic
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    // Derive the HD wallet key
    final masterKey = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    
    // Create Ethereum credentials
    final privateKey = EthPrivateKey.fromHex(bytesToHex(masterKey.key));
    final address = privateKey.address.hexEip55;
    
    // Encrypt the private key and mnemonic with the PIN
    final encryptedMnemonic = _encryptionService.encrypt(mnemonic, pin);
    final encryptedPrivateKey = _encryptionService.encrypt(bytesToHex(masterKey.key), pin);
    
    // Create a unique user ID
    final userId = const Uuid().v4();
    
    // Store the encrypted data
    await _userBox.put('userId', userId);
    await _userBox.put('salt', salt);
    await _userBox.put('encryptedMnemonic', encryptedMnemonic);
    await _userBox.put('encryptedPrivateKey', encryptedPrivateKey);
    await _userBox.put('walletAddress', address);
    
    // Set the user as logged in
    _userId = userId;
    _userWalletAddress = address;
    _userPublicKey = privateKey.address.hex;
    _isLoggedIn = true;
    
    notifyListeners();
    
    return {
      'address': address,
      'mnemonic': mnemonic, // Only return this for backup purposes
    };
  }
  
  // Login with PIN
  Future<bool> login(String pin) async {
    try {
      if (!_userBox.containsKey('userId') || 
          !_userBox.containsKey('encryptedPrivateKey') ||
          !_userBox.containsKey('walletAddress')) {
        return false;
      }
      
      final encryptedPrivateKey = _userBox.get('encryptedPrivateKey');
      
      // Try to decrypt the private key with the PIN
      try {
        _encryptionService.decrypt(encryptedPrivateKey, pin);
        
        // If decryption succeeded, set user as logged in
        _userId = _userBox.get('userId');
        _userWalletAddress = _userBox.get('walletAddress');
        _isLoggedIn = true;
        
        notifyListeners();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  // Login with biometrics
  Future<bool> loginWithBiometrics() async {
    try {
      final authenticated = await authenticateWithBiometrics(
        'Authenticate to access your identity wallet',
      );
      
      if (authenticated) {
        _userId = _userBox.get('userId');
        _userWalletAddress = _userBox.get('walletAddress');
        _isLoggedIn = true;
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Logout
  void logout() {
    _userId = null;
    _userWalletAddress = null;
    _userPublicKey = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }
  
  // Get private key (requires authentication)
  Future<String?> getPrivateKey(String pin) async {
    try {
      final encryptedPrivateKey = _userBox.get('encryptedPrivateKey');
      return _encryptionService.decrypt(encryptedPrivateKey, pin);
    } catch (e) {
      return null;
    }
  }
  
  // Recover account from mnemonic phrase
  Future<bool> recoverFromMnemonic(String mnemonic, String newPin) async {
    try {
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        return false;
      }
      
      // Generate seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Derive the HD wallet key
      final masterKey = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
      
      // Create Ethereum credentials
      final privateKey = EthPrivateKey.fromHex(bytesToHex(masterKey.key));
      final address = privateKey.address.hexEip55;
      
      // Generate a random salt
      final salt = const Uuid().v4();
      
      // Encrypt the private key and mnemonic with the new PIN
      final encryptedMnemonic = _encryptionService.encrypt(mnemonic, newPin);
      final encryptedPrivateKey = _encryptionService.encrypt(bytesToHex(masterKey.key), newPin);
      
      // Create a unique user ID
      final userId = const Uuid().v4();
      
      // Store the encrypted data
      await _userBox.put('userId', userId);
      await _userBox.put('salt', salt);
      await _userBox.put('encryptedMnemonic', encryptedMnemonic);
      await _userBox.put('encryptedPrivateKey', encryptedPrivateKey);
      await _userBox.put('walletAddress', address);
      
      // Set the user as logged in
      _userId = userId;
      _userWalletAddress = address;
      _userPublicKey = privateKey.address.hex;
      _isLoggedIn = true;
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Helper method to convert bytes to hex string
  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
} 