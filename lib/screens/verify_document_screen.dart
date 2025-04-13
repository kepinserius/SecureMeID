import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/utils/app_theme.dart';

class VerifyDocumentScreen extends StatefulWidget {
  const VerifyDocumentScreen({Key? key}) : super(key: key);

  @override
  State<VerifyDocumentScreen> createState() => _VerifyDocumentScreenState();
}

class _VerifyDocumentScreenState extends State<VerifyDocumentScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _verificationData;
  String? _errorMessage;
  DateTime? _expiryTime;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationData = null;
      _isVerified = false;
    });

    try {
      final documentService = Provider.of<DocumentService>(context, listen: false);
      
      final result = await documentService.verifyToken(token);
      
      if (result['expired'] == true) {
        setState(() {
          _errorMessage = 'Token ini telah kedaluwarsa';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isVerified = true;
        _verificationData = result['data'];
        _expiryTime = DateTime.fromMillisecondsSinceEpoch(result['expiryTime']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Token tidak valid atau kedaluwarsa: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _tokenController.text = data.text!;
      });
    }
  }

  String _formatExpiryTime() {
    if (_expiryTime == null) return '';
    
    final now = DateTime.now();
    final difference = _expiryTime!.difference(now);
    
    if (difference.isNegative) {
      return 'Kedaluwarsa';
    }
    
    if (difference.inHours > 0) {
      return '${difference.inHours}j ${difference.inMinutes % 60}m tersisa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${difference.inSeconds % 60}d tersisa';
    } else {
      return '${difference.inSeconds}d tersisa';
    }
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType) {
      case DocumentType.idCard:
        return Icons.credit_card;
      case DocumentType.passport:
        return Icons.book;
      case DocumentType.drivingLicense:
        return Icons.directions_car;
      case DocumentType.birthCertificate:
        return Icons.child_care;
      case DocumentType.socialSecurityCard:
        return Icons.security;
      case DocumentType.taxId:
        return Icons.receipt;
      case DocumentType.residencePermit:
        return Icons.home;
      case DocumentType.visaDocument:
        return Icons.flight;
      case DocumentType.medicalRecord:
        return Icons.medical_services;
      case DocumentType.educationCertificate:
        return Icons.school;
      case DocumentType.marriageCertificate:
        return Icons.favorite;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Dokumen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token input
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan Token Dokumen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan token yang Anda terima untuk memverifikasi dokumen.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        hintText: 'Tempel token di sini',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: _pasteFromClipboard,
                          tooltip: 'Tempel dari clipboard',
                        ),
                      ),
                      maxLines: 2,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyToken,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verifikasi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isVerified && _verificationData != null) ...[
              const SizedBox(height: 24),
              
              // Verification status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dokumen Terverifikasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Token valid hingga ${_expiryTime?.toString() ?? ''}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatExpiryTime(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Document information
              const Text(
                'Informasi Dokumen',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              
              // Document card
              if (_verificationData!.containsKey('document_type') ||
                  _verificationData!.containsKey('document_name')) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (_verificationData!.containsKey('document_type'))
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getDocumentIcon(_verificationData!['document_type']),
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_verificationData!.containsKey('document_name'))
                                Text(
                                  _verificationData!['document_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              if (_verificationData!.containsKey('document_type')) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DocumentType.getDisplayName(_verificationData!['document_type']),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Metadata
              final fieldsToDisplay = _verificationData!.entries.where((entry) =>
                  entry.key != 'document_type' &&
                  entry.key != 'document_name').toList();
              
              if (fieldsToDisplay.isNotEmpty) ...[
                const Text(
                  'Data Dokumen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: fieldsToDisplay.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = fieldsToDisplay[index];
                      
                      // Format field name for display
                      String displayName = entry.key.replaceAll('_', ' ');
                      displayName = displayName[0].toUpperCase() + displayName.substring(1);
                      
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Verifikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Informasi ini telah diverifikasi dari blockchain. Data yang ditampilkan di sini hanya mencakup apa yang pemilik dokumen pilih untuk dibagikan.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 