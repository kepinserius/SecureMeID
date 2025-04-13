import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secureme_id/services/encryption_service.dart';

class IPFSService extends ChangeNotifier {
  // This would normally connect to an IPFS node
  // For this project, we simulate IPFS storage

  final String _ipfsApiUrl = 'https://ipfs.infura.io:5001/api/v0';
  final String _ipfsGatewayUrl = 'https://ipfs.io/ipfs';
  final EncryptionService _encryptionService = EncryptionService();

  // Simulated IPFS storage (for development without actual IPFS)
  Map<String, dynamic> _simulatedStorage = {};
  final _storageBox = Hive.box('settings');

  IPFSService() {
    _loadStorageFromDisk();
  }

  // Simulate IPFS by storing locally
  Future<void> _loadStorageFromDisk() async {
    if (_storageBox.containsKey('ipfsSimulator')) {
      final String jsonString = _storageBox.get('ipfsSimulator');
      _simulatedStorage = json.decode(jsonString);
    }
  }

  Future<void> _saveStorageToDisk() async {
    final String jsonString = json.encode(_simulatedStorage);
    await _storageBox.put('ipfsSimulator', jsonString);
  }

  // Generate a hash similar to IPFS CID
  String _generateSimulatedCID(String content) {
    final contentHash = _encryptionService.hashData(content);
    return 'Qm${contentHash.substring(0, 44)}';
  }

  // Upload file to IPFS
  Future<String> uploadFile(File file, {String? encryptionKey}) async {
    try {
      // Read file content
      final bytes = await file.readAsBytes();

      // Encrypt content if encryption key is provided
      String content;
      if (encryptionKey != null) {
        // Convert bytes to base64 string for encryption
        final base64Content = base64Encode(bytes);
        content =
            await _encryptionService.encryptData(base64Content, encryptionKey);
      } else {
        content = base64Encode(bytes);
      }

      // In a real implementation, you would upload to IPFS here
      // For this demo, we'll simulate by storing locally
      final cid = _generateSimulatedCID(content);
      _simulatedStorage[cid] = content;
      await _saveStorageToDisk();

      return cid;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload string data to IPFS
  Future<String> uploadString(String data, {String? encryptionKey}) async {
    try {
      // Encrypt data if encryption key is provided
      final content = encryptionKey != null
          ? await _encryptionService.encryptData(data, encryptionKey)
          : data;

      // In a real implementation, you would upload to IPFS here
      // For this demo, we'll simulate by storing locally
      final cid = _generateSimulatedCID(content);
      _simulatedStorage[cid] = content;
      await _saveStorageToDisk();

      return cid;
    } catch (e) {
      throw Exception('Failed to upload data: $e');
    }
  }

  // Download file from IPFS
  Future<Uint8List> downloadFile(String cid, {String? decryptionKey}) async {
    try {
      // In a real implementation, you would download from IPFS
      // For this demo, we'll retrieve from local storage
      if (!_simulatedStorage.containsKey(cid)) {
        throw Exception('File not found in storage');
      }

      final content = _simulatedStorage[cid];

      // Decrypt content if decryption key is provided
      String dataString;
      if (decryptionKey != null) {
        dataString =
            await _encryptionService.decryptData(content, decryptionKey);
      } else {
        dataString = content;
      }

      // Convert from base64 to bytes
      final bytes = base64Decode(dataString);
      return bytes;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Download string data from IPFS
  Future<String> downloadString(String cid, {String? decryptionKey}) async {
    try {
      // In a real implementation, you would download from IPFS
      // For this demo, we'll retrieve from local storage
      if (!_simulatedStorage.containsKey(cid)) {
        throw Exception('Data not found in storage');
      }

      final content = _simulatedStorage[cid];

      // Decrypt content if decryption key is provided
      if (decryptionKey != null) {
        return await _encryptionService.decryptData(content, decryptionKey);
      } else {
        return content;
      }
    } catch (e) {
      throw Exception('Failed to download data: $e');
    }
  }

  // Save downloaded file to disk
  Future<File> saveFileToLocal(String cid, String filename,
      {String? decryptionKey}) async {
    try {
      // Download file data
      final bytes = await downloadFile(cid, decryptionKey: decryptionKey);

      // Save to local file system
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  // Delete data from IPFS (not actually possible in real IPFS, but simulated here)
  Future<bool> deleteData(String cid) async {
    try {
      // In real IPFS, content cannot be deleted once uploaded
      // This is just for the simulation
      if (_simulatedStorage.containsKey(cid)) {
        _simulatedStorage.remove(cid);
        await _saveStorageToDisk();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get IPFS gateway URL for CID
  String getGatewayUrl(String cid) {
    return '$_ipfsGatewayUrl/$cid';
  }

  // For a real IPFS implementation, connect to an IPFS node
  Future<String> _realUploadToIPFS(Uint8List bytes) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_ipfsApiUrl/add'));

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'upload.bin',
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['Hash'];
      } else {
        throw Exception('Failed to upload to IPFS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('IPFS upload error: $e');
    }
  }

  // For a real IPFS implementation, download from an IPFS node
  Future<Uint8List> _realDownloadFromIPFS(String cid) async {
    try {
      final response = await http.get(Uri.parse('$_ipfsApiUrl/cat?arg=$cid'));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download from IPFS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('IPFS download error: $e');
    }
  }
}
