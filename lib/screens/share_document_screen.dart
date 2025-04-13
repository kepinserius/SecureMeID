import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class ShareDocumentScreen extends StatefulWidget {
  final Document document;
  
  const ShareDocumentScreen({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<ShareDocumentScreen> createState() => _ShareDocumentScreenState();
}

class _ShareDocumentScreenState extends State<ShareDocumentScreen> {
  bool _isLoading = false;
  String? _tokenCid;
  Map<String, bool> _selectedFields = {};
  int _expiryTime = 15; // minutes

  @override
  void initState() {
    super.initState();
    _initializeFieldSelection();
  }
  
  void _initializeFieldSelection() {
    // Default all fields to selected
    setState(() {
      // Add basic document fields
      _selectedFields['document_type'] = true;
      _selectedFields['document_name'] = true;
      
      // Add all metadata fields
      for (final key in widget.document.metadata.keys) {
        _selectedFields[key] = true;
      }
    });
  }
  
  Future<void> _generateToken(String pin) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final documentService = Provider.of<DocumentService>(context, listen: false);
      
      // Get only the selected fields
      final List<String> fieldsToShare = _selectedFields.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      // Generate token
      final result = await documentService.generateVerificationToken(
        documentId: widget.document.id,
        pin: pin,
        expiryInMinutes: _expiryTime,
        fieldsToShare: fieldsToShare,
      );
      
      setState(() {
        _tokenCid = result['tokenCid'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your PIN to create a sharing token.'),
            const SizedBox(height: 16),
            PinInput(
              onCompleted: (pin) {
                Navigator.of(context).pop();
                _generateToken(pin);
              },
              onChanged: (pin) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String documentTypeName = DocumentType.getDisplayName(widget.document.type);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getDocumentIcon(widget.document.type),
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.name,
                            style: AppTheme.subheadingStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            documentTypeName,
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.document.isVerified) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
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
            const SizedBox(height: 24),
            
            // Select fields to share
            Text(
              'Select Information to Share',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose what information you want to share with others.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Basic document fields
            _buildCheckboxTile(
              'Document Type',
              'document_type',
            ),
            _buildCheckboxTile(
              'Document Name',
              'document_name',
            ),
            
            // Divider
            const Divider(height: 32),
            
            // Metadata fields
            if (widget.document.metadata.isNotEmpty) ...[
              Text(
                'Document Metadata',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              ...widget.document.metadata.keys.map((key) => 
                _buildCheckboxTile(
                  key,
                  key,
                ),
              ),
              const Divider(height: 32),
            ],
            
            // Expiry time
            Text(
              'Token Expiry Time',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Expire After'),
              trailing: DropdownButton<int>(
                value: _expiryTime,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 1440, child: Text('1 day')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _expiryTime = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Generate token button
            if (_tokenCid == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showPinDialog,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Generate Sharing Token'),
                ),
              ),
            
            // Show token result
            if (_tokenCid != null) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token Generated',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this token with the recipient. They will be able to view only the selected information until the token expires.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _tokenCid!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyToClipboard(_tokenCid!),
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Expires in: $_expiryTime minutes',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tokenCid = null;
                    });
                  },
                  child: const Text('Generate Another Token'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCheckboxTile(String label, String field) {
    return CheckboxListTile(
      title: Text(label),
      value: _selectedFields[field] ?? false,
      onChanged: (value) {
        setState(() {
          _selectedFields[field] = value ?? false;
        });
      },
      activeColor: AppTheme.primaryColor,
      dense: true,
    );
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
} 