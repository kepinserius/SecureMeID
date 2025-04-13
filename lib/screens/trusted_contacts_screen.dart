import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/blockchain_service.dart';
import 'package:secureme_id/utils/app_theme.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({Key? key}) : super(key: key);

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  List<String> _trustedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadTrustedContacts();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTrustedContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // Placeholder untuk mendapatkan kontak dari blockchain
      // final List<String> contacts = await authService.getTrustedContacts();
      final List<String> contacts = []; // Dummy data selama pengembangan

      setState(() {
        _trustedContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidEthereumAddress(String address) {
    // Validasi dasar: dimulai dengan 0x dan memiliki 42 karakter (termasuk 0x)
    return address.startsWith('0x') &&
        address.length == 42 &&
        RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
  }

  Future<void> _addTrustedContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final walletAddress = _addressController.text.trim();
      if (!_isValidEthereumAddress(walletAddress)) {
        throw Exception('Invalid Ethereum address');
      }

      final blockchainService =
          Provider.of<BlockchainService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final success = await blockchainService.addTrustedContact(
        userAddress: authService.walletAddress!,
        contactAddress: walletAddress,
        privateKey: authService.privateKey ?? '',
      );

      if (success) {
        _addressController.clear();
        _nameController.clear();
        await _loadTrustedContacts();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeTrustedContact(String address) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // Placeholder untuk menghapus kontak dari blockchain
      // await authService.removeTrustedContact(address);

      // Mock implementation
      setState(() {
        _trustedContacts.remove(address);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing contact: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add contact form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Trusted Contact',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trusted contacts can help you recover your account and documents if needed.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                hintText: 'Enter wallet address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addTrustedContact,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Contact list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Your Trusted Contacts',
                    style: AppTheme.subheadingStyle,
                  ),
                ),

                Expanded(
                  child: _trustedContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No trusted contacts yet',
                                style: AppTheme.bodyStyle.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _trustedContacts.length,
                          itemBuilder: (context, index) {
                            final address = _trustedContacts[index];
                            return ListTile(
                              title: Text(_shortenAddress(address)),
                              subtitle: const Text('Trusted Contact'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () => _copyToClipboard(address),
                                    tooltip: 'Copy address',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _showDeleteConfirmation(address),
                                    tooltip: 'Remove contact',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteConfirmation(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text('Are you sure you want to remove this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeTrustedContact(address);
            },
            child: const Text('Remove'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
