import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/blockchain_service.dart';
import 'package:secureme_id/services/encryption_service.dart';
import 'package:secureme_id/services/ipfs_service.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/services/icp_service.dart';
import 'package:flutter/foundation.dart';

class DocumentService extends ChangeNotifier {
  final EncryptionService _encryptionService = EncryptionService();
  final IPFSService _ipfsService = IPFSService();
  final BlockchainService _blockchainService = BlockchainService();
  final _documentsBox = Hive.box('settings');
  final ICPService _icpService = ICPService();

  // Local cache of documents for faster access
  List<Document> _documents = [];
  bool _isLoaded = false;

  List<Document> get documents => _documents;

  DocumentService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isLoaded) return;

    await _icpService.initialize();

    // Coba memuat dokumen jika pengguna sudah terotentikasi
    _isLoaded = await _checkAuthentication();
    if (_isLoaded) {
      await _loadDocuments();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> _checkAuthentication() async {
    try {
      // Cek apakah identitas sudah dimuat dari penyimpanan lokal oleh ICPService
      // Ini diimplementasikan secara internal di ICPService.initialize()
      return true; // Placeholder, perlu diimplementasikan
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!_isLoaded) await _initialize();

    try {
      final success = await _icpService.authenticateWithInternetIdentity();
      if (success) {
        _isLoaded = true;
        await _loadDocuments();
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _icpService.logout();
    _isLoaded = false;
    _documents = [];
    notifyListeners();
  }

  Future<void> _loadDocuments() async {
    // Placeholder: Dalam implementasi sebenarnya, dokumen akan diambil dari ICP
    // Untuk saat ini, kita gunakan data dummy
    _documents = [
      Document(
        id: '1',
        name: 'KTP',
        type: DocumentType.idCard,
        fields: {
          'full_name': 'John Doe',
          'id_number': '1234567890',
          'date_of_birth': '1990-01-01',
          'gender': 'Male',
          'address': 'Jl. Sudirman No. 123, Jakarta',
          'religion': 'Islam',
          'marital_status': 'Single',
          'occupation': 'Software Engineer',
          'citizenship': 'WNI',
          'valid_until': '2025-01-01',
        },
      ),
      Document(
        id: '2',
        name: 'SIM',
        type: DocumentType.drivingLicense,
        fields: {
          'full_name': 'John Doe',
          'license_number': '98765432100',
          'date_of_birth': '1990-01-01',
          'address': 'Jl. Sudirman No. 123, Jakarta',
          'issue_date': '2020-01-01',
          'expiry_date': '2025-01-01',
          'class': 'A',
        },
      ),
    ];
  }

  Future<Document?> getDocument(String id) async {
    if (!_isLoaded) return null;

    try {
      // Cari dokumen dari cache dulu
      final cached = _documents.firstWhere((doc) => doc.id == id,
          orElse: () => Document.empty());
      if (cached.id.isNotEmpty) return cached;

      // Jika tidak ada di cache, ambil dari ICP
      final result = await _icpService.getDocument(id);
      if (result['success'] == true) {
        final doc = Document.fromJson(jsonDecode(result['decryptedData']));

        // Tambahkan ke cache
        _documents.add(doc);
        notifyListeners();

        return doc;
      }

      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  // Commented out previous addDocument to avoid duplication
  // Future<bool> addDocument(Document document) async {
  //   if (!_isLoaded) return false;

  //   try {
  //     final result = await _icpService.storeDocument(document.toJson());
  //     if (result['success'] == true) {
  //       document.id = result['id'];
  //       _documents.add(document);
  //       notifyListeners();
  //       return true;
  //     }

  //     return false;
  //   } catch (e) {
  //     print('Error adding document: $e');
  //     return false;
  //   }
  // }

  // Add a new document
  Future<bool> addDocument({
    required String userId,
    required String userWalletAddress,
    required String privateKey,
    required String documentType,
    required String documentName,
    required File documentFile,
    required String pin,
    Map<String, dynamic>? metadata,
    Document? document, // Optional document object
  }) async {
    try {
      // Use provided document or generate a new one
      Document newDocument;
      if (document != null) {
        newDocument = document;
      } else {
        // Generate a unique document ID
        final documentId = const Uuid().v4();

        // Create document object
        newDocument = Document(
          id: documentId,
          type: documentType,
          name: documentName,
          fields: {}, // Default empty fields
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: false,
          metadata: metadata,
          owner: userWalletAddress,
        );
      }

      // Read file as bytes
      final bytes = await documentFile.readAsBytes();

      // Create document hash
      final documentHash = _encryptionService.hashData(base64Encode(bytes));

      // Encrypt document with PIN
      final encryptedIpfsHash = await _ipfsService.uploadFile(
        documentFile,
        encryptionKey: pin,
      );

      // Store document reference in blockchain
      final txHash = await _blockchainService.storeDocument(
        userAddress: userWalletAddress,
        documentType: newDocument.type,
        documentHash: documentHash,
        ipfsCid: encryptedIpfsHash,
        privateKey: privateKey,
      );

      // Update document with new info
      final finalDocument = newDocument.copyWith(
        ipfsCid: encryptedIpfsHash,
        txHash: txHash,
      );

      // Add to local cache
      _documents.add(finalDocument);
      await _saveDocumentsToDisk();

      notifyListeners();
      return true;
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  // Get a document by ID
  Document? getDocumentById(String documentId) {
    try {
      return _documents.firstWhere((doc) => doc.id == documentId);
    } catch (e) {
      return null;
    }
  }

  // Get documents by type
  List<Document> getDocumentsByType(String documentType) {
    return _documents.where((doc) => doc.type == documentType).toList();
  }

  // Get document file from IPFS
  Future<File> getDocumentFile(
      String documentId, String pin, String localFileName) async {
    try {
      final document = getDocumentById(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }

      return await _ipfsService.saveFileToLocal(
        document.ipfsCid ?? '',
        localFileName,
        decryptionKey: pin,
      );
    } catch (e) {
      throw Exception('Failed to get document file: $e');
    }
  }

  // Update document metadata
  Future<Document> updateDocumentMetadata(
    String documentId,
    Map<String, dynamic> newMetadata,
    String privateKey,
  ) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index == -1) {
        throw Exception('Document not found');
      }

      // Update document
      final document = _documents[index];
      final updatedMetadata = document.metadata != null
          ? {...document.metadata!, ...newMetadata}
          : newMetadata;

      final updatedDocument = document.copyWith(
        metadata: updatedMetadata,
        updatedAt: DateTime.now(),
      );

      // Replace in list
      _documents[index] = updatedDocument;
      await _saveDocumentsToDisk();

      notifyListeners();
      return updatedDocument;
    } catch (e) {
      throw Exception('Failed to update document metadata: $e');
    }
  }

  // Verify a document (e.g., by an authority)
  Future<Document> verifyDocument({
    required String documentId,
    required String verifierAddress,
    required String privateKey,
  }) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index == -1) {
        throw Exception('Document not found');
      }

      final document = _documents[index];

      // Update verification on blockchain
      final success = await _blockchainService.verifyDocument(
        userAddress: document.owner ?? '',
        documentId: document.id,
        verifierAddress: verifierAddress,
        privateKey: privateKey,
      );

      if (!success) {
        throw Exception('Failed to verify document on blockchain');
      }

      // Update local document
      final updatedDocument = document.copyWith(
        isVerified: true,
        verifiedBy: verifierAddress,
        verifiedAt: DateTime.now(),
      );

      // Replace in list
      _documents[index] = updatedDocument;
      await _saveDocumentsToDisk();

      notifyListeners();
      return updatedDocument;
    } catch (e) {
      throw Exception('Failed to verify document: $e');
    }
  }

  // Synchronize documents with blockchain
  Future<void> syncWithBlockchain(String userWalletAddress) async {
    try {
      // Get documents from blockchain
      final blockchainDocuments =
          await _blockchainService.getAllDocuments(userWalletAddress);

      // Update local documents with blockchain data
      for (final blockchainDoc in blockchainDocuments) {
        final documentId = blockchainDoc['id'];
        final documentHash = blockchainDoc['documentHash'];
        final ipfsCid = blockchainDoc['ipfsCid'];
        final documentType = blockchainDoc['documentType'];
        final isVerified = blockchainDoc['verified'] ?? false;

        // Check if document exists in local cache
        final existingIndex =
            _documents.indexWhere((doc) => doc.id == documentId);

        if (existingIndex == -1) {
          // Add new document to local cache
          _documents.add(Document(
            id: documentId,
            type: documentType,
            name: 'Document from blockchain',
            fields: {}, // Empty fields
            ipfsCid: ipfsCid,
            owner: userWalletAddress,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(blockchainDoc['timestamp']),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(blockchainDoc['timestamp']),
            isVerified: isVerified,
            verifiedBy: blockchainDoc['verifier'],
            verifiedAt: blockchainDoc['verificationTimestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    blockchainDoc['verificationTimestamp'])
                : null,
            metadata: {},
            txHash: '',
          ));
        } else {
          // Update existing document
          final existingDoc = _documents[existingIndex];
          _documents[existingIndex] = existingDoc.copyWith(
            isVerified: isVerified,
            verifiedBy: blockchainDoc['verifier'],
            verifiedAt: blockchainDoc['verificationTimestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    blockchainDoc['verificationTimestamp'])
                : null,
          );
        }
      }

      await _saveDocumentsToDisk();
      notifyListeners();
    } catch (e) {
      print('Error syncing with blockchain: $e');
    }
  }

  // Load documents from local storage
  Future<void> _loadDocumentsFromDisk() async {
    try {
      if (_documentsBox.containsKey('documentsList')) {
        final jsonString = _documentsBox.get('documentsList');
        final List<dynamic> jsonList = json.decode(jsonString);

        _documents =
            jsonList.map((jsonItem) => Document.fromJson(jsonItem)).toList();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // If there's an error, initialize with empty list
      _documents = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Save documents to local storage
  Future<void> _saveDocumentsToDisk() async {
    try {
      final jsonList = _documents.map((doc) => doc.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _documentsBox.put('documentsList', jsonString);
    } catch (e) {
      print('Error saving documents: $e');
    }
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      return await _icpService.verifyDocument(token);
    } catch (e) {
      print('Error verifying token: $e');

      // Untuk demo/testing, decode token lokal
      try {
        final decodedJson = utf8.decode(base64Decode(token));
        final tokenData = jsonDecode(decodedJson);

        return {
          'success': true,
          'data': tokenData,
          'expired': false,
          'expiryTime':
              DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
        };
      } catch (e) {
        return {'success': false, 'error': 'Invalid token format'};
      }
    }
  }

  // Delete a document
  Future<bool> deleteDocument(String id) async {
    if (!_isLoaded) return false;

    try {
      // Remove from local cache
      _documents.removeWhere((doc) => doc.id == id);
      await _saveDocumentsToDisk();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Generate verification token for document sharing
  Future<Map<String, dynamic>> generateVerificationToken(
      String documentId, List<String> fields, int expirySeconds) async {
    if (!_isLoaded) return {'success': false, 'error': 'Not authenticated'};

    try {
      return await _icpService.generateVerificationToken(
          documentId, fields, expirySeconds);
    } catch (e) {
      print('Error generating verification token: $e');

      // Dummy token untuk testing
      final doc = _documents.firstWhere(
        (doc) => doc.id == documentId,
        orElse: () => Document.empty(),
      );

      if (doc.id.isEmpty) {
        return {'success': false, 'error': 'Document not found'};
      }

      final Map<String, dynamic> selectedFields = {};
      for (final field in fields) {
        if (doc.fields.containsKey(field)) {
          selectedFields[field] = doc.fields[field];
        }
      }

      final expiryTime = DateTime.now()
          .add(Duration(seconds: expirySeconds))
          .millisecondsSinceEpoch;

      final Map<String, dynamic> tokenData = {
        'document_type': doc.type,
        'document_name': doc.name,
        ...selectedFields,
      };

      final tokenStr = base64Encode(utf8.encode(jsonEncode(tokenData)));

      return {
        'success': true,
        'token': tokenStr,
        'expiryTime': expiryTime,
      };
    }
  }
}
