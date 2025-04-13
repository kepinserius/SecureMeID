import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({Key? key}) : super(key: key);

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedDocumentType = DocumentType.idCard;
  File? _documentFile;
  bool _isLoading = false;
  final Map<String, dynamic> _metadata = {};
  final Map<String, TextEditingController> _fieldControllers = {};

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _documentFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addDocument(String pin) async {
    if (!_formKey.currentState!.validate() || _documentFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState!.save();

      // Collect field data
      final Map<String, dynamic> fields = {};

      for (var entry in _fieldControllers.entries) {
        fields[entry.key] = entry.value.text;
      }

      final documentService =
          Provider.of<DocumentService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final document = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedDocumentType,
        fields: fields,
        owner: authService.walletAddress,
        metadata: _metadata,
      );

      await documentService.addDocument(
        userId: authService.userId ?? '',
        userWalletAddress: authService.walletAddress ?? '',
        privateKey: authService.privateKey ?? '',
        documentType: document.type,
        documentName: document.name,
        documentFile: _documentFile!,
        pin: pin,
        document: document,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document added successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPINDialog() {
    if (!_formKey.currentState!.validate() || _documentFile == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your PIN to encrypt and add this document.'),
            const SizedBox(height: 16),
            PinInput(
              onCompleted: (pin) {
                Navigator.of(context).pop();
                _addDocument(pin);
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

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDocumentType,
      decoration: const InputDecoration(
        labelText: 'Document Type',
        border: OutlineInputBorder(),
      ),
      items: DocumentType.getAllTypes().map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(DocumentType.getDisplayName(type)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDocumentType = value;
            // Reset field controllers when document type changes
            for (var controller in _fieldControllers.values) {
              controller.dispose();
            }
            _fieldControllers.clear();
            _setupFieldsForDocumentType();
          });
        }
      },
    );
  }

  void _setupFieldsForDocumentType() {
    // Add default fields based on document type
    switch (_selectedDocumentType) {
      case DocumentType.idCard:
        _addFieldController('full_name', 'Full Name');
        _addFieldController('id_number', 'ID Number');
        _addFieldController('date_of_birth', 'Date of Birth');
        _addFieldController('address', 'Address');
        break;
      case DocumentType.passport:
        _addFieldController('full_name', 'Full Name');
        _addFieldController('passport_number', 'Passport Number');
        _addFieldController('nationality', 'Nationality');
        _addFieldController('issue_date', 'Issue Date');
        _addFieldController('expiry_date', 'Expiry Date');
        break;
      case DocumentType.drivingLicense:
        _addFieldController('full_name', 'Full Name');
        _addFieldController('license_number', 'License Number');
        _addFieldController('vehicle_classes', 'Vehicle Classes');
        _addFieldController('issue_date', 'Issue Date');
        _addFieldController('expiry_date', 'Expiry Date');
        break;
      // Add more document types as needed
      default:
        // Default generic fields
        _addFieldController('full_name', 'Full Name');
        _addFieldController('document_number', 'Document Number');
        _addFieldController('issue_date', 'Issue Date');
    }
  }

  void _addFieldController(String fieldName, String displayName) {
    _fieldControllers[fieldName] = TextEditingController();
  }

  Widget _buildFieldInputs() {
    return Column(
      children: _fieldControllers.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: entry.value,
            decoration: InputDecoration(
              labelText: entry.key
                  .split('_')
                  .map((word) => word.isEmpty
                      ? ''
                      : '${word[0].toUpperCase()}${word.substring(1)}')
                  .join(' '),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter ${entry.key.replaceAll('_', ' ')}';
              }
              return null;
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _setupFieldsForDocumentType();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickDocument,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor
                                .withValues(alpha: 0.1), // Fixed withOpacity
                            borderRadius: BorderRadius.circular(12),
                            image: _documentFile != null
                                ? DecorationImage(
                                    image: FileImage(_documentFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _documentFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate,
                                      size: 64,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select document image',
                                      style: AppTheme.bodyStyle,
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_documentFile == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select a document image',
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Document name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a document name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Document type dropdown
                    _buildDocumentTypeDropdown(),
                    const SizedBox(height: 24),

                    // Document fields
                    Text(
                      'Document Fields',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldInputs(),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showPINDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Add Document'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
