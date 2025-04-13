import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/auth/login_screen.dart';
import 'package:secureme_id/screens/trusted_contacts_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/blockchain_service.dart';
import 'package:secureme_id/utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  int _trusteedContactsCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadTrustedContacts();
  }
  
  Future<void> _loadTrustedContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final blockchainService = Provider.of<BlockchainService>(context, listen: false);
      
      if (authService.walletAddress != null) {
        final trustedContacts = await blockchainService.getTrustedContacts(
          authService.walletAddress!,
        );
        
        setState(() {
          _trusteedContactsCount = trustedContacts.length;
        });
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
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
  
  void _navigateToTrustedContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrustedContactsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final walletAddress = authService.walletAddress ?? 'Not available';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Secured Identity',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your decentralized identity wallet',
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Wallet information
          Text(
            'Wallet Information',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Wallet Address',
            value: walletAddress,
            onTap: () => _copyToClipboard(walletAddress),
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            title: 'Blockchain',
            value: 'Ethereum (Simulated)',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 32),
          
          // Security
          Text(
            'Security',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: 'Trusted Contacts',
            description: '$_trusteedContactsCount contacts added',
            icon: Icons.people,
            onTap: _navigateToTrustedContacts,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            title: 'Backup Recovery Phrase',
            description: 'Securely store your recovery phrase',
            icon: Icons.backup,
            onTap: () {
              // Navigate to backup screen
            },
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            title: 'Change PIN',
            description: 'Update your security PIN',
            icon: Icons.lock,
            onTap: () {
              // Navigate to change PIN screen
            },
          ),
          const SizedBox(height: 32),
          
          // Account
          Text(
            'Account',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: 'Privacy Policy',
            description: 'Read our privacy policy',
            icon: Icons.privacy_tip,
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            title: 'Terms of Service',
            description: 'Read our terms of service',
            icon: Icons.description,
            onTap: () {
              // Navigate to terms of service
            },
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            title: 'About',
            description: 'About SecureMeID',
            icon: Icons.info,
            onTap: () {
              // Navigate to about screen
            },
          ),
          const SizedBox(height: 32),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon ?? Icons.info,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    const Icon(
                      Icons.copy,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
} 