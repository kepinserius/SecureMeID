import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/home_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/blockchain_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _pin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  
  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }
  
  Future<void> _recoverWallet() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    
    // Validate PINs
    if (_pin.length < 6) {
      setState(() {
        _errorMessage = 'PIN must be at least 6 digits';
      });
      return;
    }
    
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final mnemonic = _mnemonicController.text.trim();
      
      final success = await authService.recoverFromMnemonic(mnemonic, _pin);
      
      if (success) {
        // Sync with blockchain
        final blockchainService = Provider.of<BlockchainService>(context, listen: false);
        final userAddress = authService.walletAddress;
        
        if (userAddress != null) {
          // No need to await this, it can run in the background
          blockchainService.getAllDocuments(userAddress);
        }
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to recover wallet. Please check your recovery phrase.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Recovery error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recover Your Identity Wallet',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your recovery phrase and create a new PIN',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                
                // Recovery phrase
                Text(
                  'Recovery Phrase',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mnemonicController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter your 12 or 24 word recovery phrase',
                    helperText: 'Words should be separated by spaces',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Recovery phrase is required';
                    }
                    
                    final wordCount = value.trim().split(' ').length;
                    if (wordCount != 12 && wordCount != 24) {
                      return 'Recovery phrase must be 12 or 24 words';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Create new PIN
                Text(
                  'Create New PIN',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 16),
                PinInput(
                  onCompleted: (pin) {
                    setState(() {
                      _pin = pin;
                    });
                  },
                  onChanged: (pin) {
                    setState(() {
                      _pin = pin;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Confirm PIN
                Text(
                  'Confirm PIN',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 16),
                PinInput(
                  onCompleted: (pin) {
                    setState(() {
                      _confirmPin = pin;
                    });
                    // Auto recover when PIN is complete
                    if (_pin.length >= 6 && _pin == pin) {
                      _recoverWallet();
                    }
                  },
                  onChanged: (pin) {
                    setState(() {
                      _confirmPin = pin;
                      _errorMessage = '';
                    });
                  },
                ),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage,
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Recover button
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _recoverWallet,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Recover Wallet'),
                    ),
                  ),
                ),
                
                // Help text
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'If you don\'t have a recovery phrase, contact your trusted contacts for account recovery.',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 