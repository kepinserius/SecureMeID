import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menangani interaksi dengan Internet Computer Protocol (ICP)
class ICPService {
  static const String _keyIdentity = 'icp_identity';
  static const String _canisterIdDocuments = 'rrkah-fqaaa-aaaaa-aaaaq-cai'; // Ganti dengan canister ID yang sebenarnya
  
  late JavascriptRuntime _jsRuntime;
  bool _isInitialized = false;
  String? _identity;
  
  /// Inisialisasi service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Inisialisasi JavaScript runtime
    _jsRuntime = getJavascriptRuntime();
    
    // Load agent.js
    final String agentScript = await rootBundle.loadString('assets/js/agent.js');
    await _jsRuntime.evaluateAsync('''
      // Muat library agent-js dari CDN
      if (typeof window.ic === 'undefined') {
        window.ic = {};
        importScripts('https://unpkg.com/@dfinity/agent/lib/index.js');
        importScripts('https://unpkg.com/@dfinity/auth-client/lib/index.js');
        importScripts('https://unpkg.com/@dfinity/identity/lib/index.js');
      }
    ''');
    
    // Evaluasi script agent.js
    await _jsRuntime.evaluateAsync(agentScript);
    
    // Coba memuat identitas yang tersimpan
    await _loadSavedIdentity();
    
    _isInitialized = true;
  }
  
  /// Memuat identitas yang tersimpan di shared preferences
  Future<void> _loadSavedIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdentity = prefs.getString(_keyIdentity);
    
    if (savedIdentity != null) {
      try {
        // Buat identitas dari kunci yang tersimpan
        final result = await _jsRuntime.evaluateAsync('''
          const identity = window.icpAgent.createIdentityFromKey('$savedIdentity');
          JSON.stringify({ success: true, principal: identity.getPrincipal().toString() });
        ''');
        
        final Map<String, dynamic> response = jsonDecode(result.stringResult);
        if (response['success'] == true) {
          _identity = savedIdentity;
        }
      } catch (e) {
        print('Error loading saved identity: $e');
      }
    }
  }
  
  /// Autentikasi menggunakan Internet Identity
  Future<bool> authenticateWithInternetIdentity() async {
    if (!_isInitialized) await initialize();
    
    try {
      final result = await _jsRuntime.evaluateAsync('''
        window.icpAgent.authenticateWithII('${_canisterIdDocuments}')
          .then(identity => {
            return JSON.stringify({ 
              success: true, 
              identity: JSON.stringify(identity.toJSON()),
              principal: identity.getPrincipal().toString() 
            });
          })
          .catch(error => {
            return JSON.stringify({ success: false, error: error.toString() });
          });
      ''');
      
      final Map<String, dynamic> response = jsonDecode(result.stringResult);
      if (response['success'] == true) {
        _identity = response['identity'];
        
        // Simpan identitas di shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyIdentity, _identity!);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
  
  /// Menyimpan dokumen terenkripsi di ICP
  Future<Map<String, dynamic>> storeDocument(Map<String, dynamic> document) async {
    if (!_isInitialized) await initialize();
    if (_identity == null) throw Exception('User not authenticated');
    
    try {
      // 1. Enkripsi dokumen di client-side
      final documentJson = jsonEncode(document);
      final encryptResult = await _jsRuntime.evaluateAsync('''
        const encryptedDoc = window.icpAgent.encryptDocument(`$documentJson`, null);
        JSON.stringify(encryptedDoc);
      ''');
      
      final encryptedData = jsonDecode(encryptResult.stringResult);
      
      // 2. Buat aktor untuk interaksi dengan canister
      final actorResult = await _jsRuntime.evaluateAsync('''
        async function callCanister() {
          const identity = window.icpAgent.createIdentityFromKey('$_identity');
          
          // Membuat IDL Factory (placeholder, harusnya dari file terpisah)
          const idlFactory = ({ IDL }) => {
            return IDL.Service({
              'storeDocument': IDL.Func([IDL.Text, IDL.Text], [IDL.Record({
                'id': IDL.Text,
                'success': IDL.Bool
              })], []),
            });
          };
          
          const actor = await window.icpAgent.createActor('${_canisterIdDocuments}', idlFactory, { identity });
          
          // Panggil metode canister
          const result = await actor.storeDocument(
            JSON.stringify(${encryptResult.stringResult}),
            JSON.stringify(${jsonEncode(document['metadata'] ?? {})})
          );
          
          return JSON.stringify(result);
        }
        
        return await callCanister();
      ''');
      
      return jsonDecode(actorResult.stringResult);
    } catch (e) {
      print('Error storing document: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Mendapatkan dokumen berdasarkan ID
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    if (!_isInitialized) await initialize();
    if (_identity == null) throw Exception('User not authenticated');
    
    try {
      final actorResult = await _jsRuntime.evaluateAsync('''
        async function getDocumentFromCanister() {
          const identity = window.icpAgent.createIdentityFromKey('$_identity');
          
          // Placeholder IDL Factory
          const idlFactory = ({ IDL }) => {
            return IDL.Service({
              'getDocument': IDL.Func([IDL.Text], [IDL.Record({
                'encryptedData': IDL.Text,
                'metadata': IDL.Text,
                'owner': IDL.Principal,
                'success': IDL.Bool
              })], []),
            });
          };
          
          const actor = await window.icpAgent.createActor('${_canisterIdDocuments}', idlFactory, { identity });
          const result = await actor.getDocument('$documentId');
          
          if (result.success) {
            // Dekripsi dokumen
            const encryptedData = JSON.parse(result.encryptedData);
            const decrypted = window.icpAgent.decryptDocument(
              encryptedData.encryptedData,
              encryptedData.nonce,
              '$_identity'
            );
            
            return JSON.stringify({
              ...result,
              decryptedData: decrypted.decryptedData,
              metadata: JSON.parse(result.metadata)
            });
          }
          
          return JSON.stringify(result);
        }
        
        return await getDocumentFromCanister();
      ''');
      
      return jsonDecode(actorResult.stringResult);
    } catch (e) {
      print('Error getting document: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Membuat token verifikasi untuk dokumen
  Future<Map<String, dynamic>> generateVerificationToken(
    String documentId, 
    List<String> fields, 
    int expirySeconds
  ) async {
    if (!_isInitialized) await initialize();
    if (_identity == null) throw Exception('User not authenticated');
    
    try {
      final fieldsJson = jsonEncode(fields);
      final actorResult = await _jsRuntime.evaluateAsync('''
        async function generateToken() {
          const identity = window.icpAgent.createIdentityFromKey('$_identity');
          
          // Placeholder IDL Factory
          const idlFactory = ({ IDL }) => {
            return IDL.Service({
              'generateVerificationToken': IDL.Func(
                [IDL.Text, IDL.Vec(IDL.Text), IDL.Int], 
                [IDL.Record({
                  'token': IDL.Text,
                  'expiryTime': IDL.Int,
                  'success': IDL.Bool
                })], 
                []
              ),
            });
          };
          
          const actor = await window.icpAgent.createActor('${_canisterIdDocuments}', idlFactory, { identity });
          const result = await actor.generateVerificationToken(
            '$documentId',
            $fieldsJson,
            $expirySeconds
          );
          
          return JSON.stringify(result);
        }
        
        return await generateToken();
      ''');
      
      return jsonDecode(actorResult.stringResult);
    } catch (e) {
      print('Error generating verification token: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Memverifikasi token dokumen
  Future<Map<String, dynamic>> verifyToken(String token) async {
    if (!_isInitialized) await initialize();
    
    try {
      final actorResult = await _jsRuntime.evaluateAsync('''
        async function verifyDocumentToken() {
          // Untuk verifikasi token, kita tidak memerlukan identitas
          
          // Placeholder IDL Factory
          const idlFactory = ({ IDL }) => {
            return IDL.Service({
              'verifyToken': IDL.Func(
                [IDL.Text], 
                [IDL.Record({
                  'data': IDL.Record({
                    'document_type': IDL.Text,
                    'document_name': IDL.Text,
                    'fields': IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))
                  }),
                  'expired': IDL.Bool,
                  'expiryTime': IDL.Int,
                  'success': IDL.Bool
                })], 
                []
              ),
            });
          };
          
          const actor = await window.icpAgent.createActor('${_canisterIdDocuments}', idlFactory);
          const result = await actor.verifyToken('$token');
          
          // Konversi fields dari tuple ke objek
          if (result.success && !result.expired) {
            const fields = {};
            for (const [key, value] of result.data.fields) {
              fields[key] = value;
            }
            
            return JSON.stringify({
              ...result,
              data: {
                ...result.data,
                ...fields
              }
            });
          }
          
          return JSON.stringify(result);
        }
        
        return await verifyDocumentToken();
      ''');
      
      return jsonDecode(actorResult.stringResult);
    } catch (e) {
      print('Error verifying token: $e');
      return {
        'success': false, 
        'error': e.toString(),
        // Contoh data untuk mode simulasi (development)
        'data': {
          'document_type': 'idCard',
          'document_name': 'KTP',
          'full_name': 'John Doe',
          'id_number': '1234567890',
          'date_of_birth': '1990-01-01',
          'address': 'Jl. Sudirman No. 123, Jakarta'
        },
        'expired': false,
        'expiryTime': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch
      };
    }
  }
  
  /// Logout dan hapus identitas
  Future<void> logout() async {
    if (!_isInitialized) return;
    
    _identity = null;
    
    // Hapus identitas dari shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdentity);
  }
} 