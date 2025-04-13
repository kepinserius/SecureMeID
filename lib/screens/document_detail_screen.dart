import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/screens/share_document_screen.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;

  const DocumentDetailScreen({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isLoading = false;
  bool _showDocumentPreview = false;
  File? _documentFile;

  @override
  Widget build(BuildContext context) {
    final String documentTypeName =
        DocumentType.getDisplayName(widget.document.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _navigateToShare,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuItemSelected,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit Metadata'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document preview/thumbnail
            Center(
              child: GestureDetector(
                onTap: _showDocument,
                child: _showDocumentPreview && _documentFile != null
                    ? Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_documentFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getDocumentIcon(widget.document.type),
                              size: 64,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              documentTypeName,
                              style: AppTheme.subheadingStyle,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showDocument,
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Document'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Document info
            Text(
              'Document Information',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.document.name),
            _buildInfoRow('Type', documentTypeName),
            _buildInfoRow('Date Added', _formatDate(widget.document.createdAt)),
            _buildInfoRow('Status',
                widget.document.isVerified ? 'Verified' : 'Unverified'),
            if (widget.document.isVerified &&
                widget.document.verifiedAt != null)
              _buildInfoRow(
                  'Verified On', _formatDate(widget.document.verifiedAt!)),
            if (widget.document.isVerified &&
                widget.document.verifiedBy != null)
              _buildInfoRow(
                  'Verified By', _shortenAddress(widget.document.verifiedBy!)),

            const SizedBox(height: 24),

            // Document metadata
            Text(
              'Document Metadata',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            if (widget.document.metadata == null ||
                widget.document.metadata!.isEmpty)
              const Text('No metadata available'),
            if (widget.document.metadata != null)
              ...widget.document.metadata!.entries.map(
                  (entry) => _buildInfoRow(entry.key, entry.value.toString())),

            const SizedBox(height: 24),

            // Blockchain info
            Text(
              'Blockchain Information',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Document Hash',
                _shortenHash(
                    Object.hash(widget.document.id, widget.document.name)
                        .toString())),
            if (widget.document.ipfsCid != null)
              _buildInfoRow('IPFS CID', _shortenHash(widget.document.ipfsCid!)),
            if (widget.document.txHash != null &&
                widget.document.txHash!.isNotEmpty)
              _buildInfoRow(
                  'Transaction Hash', _shortenHash(widget.document.txHash!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _shortenAddress(String address) {
    if (address.length <= 14) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  String _shortenHash(String hash) {
    if (hash.length <= 14) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 6)}';
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

  void _showDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN to view document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your PIN to decrypt and view this document.'),
            const SizedBox(height: 16),
            PinInput(
              onCompleted: (pin) {
                Navigator.of(context).pop();
                _decryptAndShowDocument(pin);
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

  Future<void> _decryptAndShowDocument(String pin) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final documentService =
          Provider.of<DocumentService>(context, listen: false);

      // Create a temporary filename for the document
      final filename = 'document_${widget.document.id}.jpg';

      final file = await documentService.getDocumentFile(
        widget.document.id,
        pin,
        filename,
      );

      setState(() {
        _documentFile = file;
        _showDocumentPreview = true;
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

  void _navigateToShare() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareDocumentScreen(document: widget.document),
      ),
    );
  }

  void _handleMenuItemSelected(String value) {
    switch (value) {
      case 'edit':
        _editMetadata();
        break;
      case 'delete':
        _deleteDocument();
        break;
    }
  }

  void _editMetadata() {
    // Implement metadata editing
  }

  void _deleteDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This will only remove it from your device, not from the blockchain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final documentService =
                  Provider.of<DocumentService>(context, listen: false);
              final success =
                  await documentService.deleteDocument(widget.document.id);

              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document deleted'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
