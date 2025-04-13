import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/models/document_model.dart';
import 'package:secureme_id/screens/add_document_screen.dart';
import 'package:secureme_id/screens/document_detail_screen.dart';
import 'package:secureme_id/screens/profile_screen.dart';
import 'package:secureme_id/screens/settings_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  String _selectedDocumentType = 'all';
  
  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }
  
  Future<void> _refreshDocuments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final documentService = Provider.of<DocumentService>(context, listen: false);
      
      if (authService.walletAddress != null) {
        await documentService.syncWithBlockchain(authService.walletAddress!);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }
  
  void _addNewDocument() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
    );
  }
  
  void _openDocumentDetails(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(document: document),
      ),
    );
  }
  
  void _selectDocumentType(String type) {
    setState(() {
      _selectedDocumentType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureMeID'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDocuments,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton(
              onPressed: _addNewDocument,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildDocumentsTab();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }
  
  Widget _buildHomeTab() {
    final authService = Provider.of<AuthService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to SecureMeID',
                              style: AppTheme.subheadingStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your secure identity wallet',
                              style: AppTheme.bodyStyle.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wallet Address',
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authService.walletAddress ?? 'Not available',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionCard(
                icon: Icons.add_circle,
                label: 'Add ID',
                onTap: _addNewDocument,
              ),
              _buildActionCard(
                icon: Icons.verified_user,
                label: 'Verify',
                onTap: () {
                  // Navigate to verification screen
                },
              ),
              _buildActionCard(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent documents
          Text(
            'Recent Documents',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 16),
          _buildRecentDocuments(),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentDocuments() {
    final documentService = Provider.of<DocumentService>(context);
    final documents = documentService.documents;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (documents.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No documents yet',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first document to get started',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addNewDocument,
                child: const Text('Add Document'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show at most 3 recent documents
    final recentDocs = documents.take(3).toList();
    
    return Column(
      children: [
        ...recentDocs.map((doc) => _buildDocumentCard(doc)),
        if (documents.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTabIndex = 1; // Switch to Documents tab
              });
            },
            child: const Text('View All Documents'),
          ),
      ],
    );
  }
  
  Widget _buildDocumentsTab() {
    final documentService = Provider.of<DocumentService>(context);
    List<Document> documents = documentService.documents;
    
    // Filter documents by type if needed
    if (_selectedDocumentType != 'all') {
      documents = documents.where((doc) => doc.type == _selectedDocumentType).toList();
    }
    
    return Column(
      children: [
        // Document type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip(DocumentType.idCard, 'ID Card'),
              _buildFilterChip(DocumentType.passport, 'Passport'),
              _buildFilterChip(DocumentType.drivingLicense, 'License'),
              _buildFilterChip(DocumentType.birthCertificate, 'Birth Cert'),
              _buildFilterChip(DocumentType.other, 'Other'),
            ],
          ),
        ),
        
        // Documents list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : documents.isEmpty
                  ? _buildEmptyDocumentsList()
                  : RefreshIndicator(
                      onRefresh: _refreshDocuments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          return _buildDocumentCard(documents[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String type, String label) {
    final isSelected = _selectedDocumentType == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          _selectDocumentType(type);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget _buildEmptyDocumentsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No documents found',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first document to get started',
            style: AppTheme.bodyStyle.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewDocument,
            icon: const Icon(Icons.add),
            label: const Text('Add Document'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentCard(Document document) {
    final String documentTypeName = DocumentType.getDisplayName(document.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDocumentDetails(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Document type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(document.type),
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      documentTypeName,
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added: ${_formatDate(document.createdAt)}',
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Verification status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: document.isVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  document.isVerified ? 'Verified' : 'Unverified',
                  style: TextStyle(
                    color: document.isVerified ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 