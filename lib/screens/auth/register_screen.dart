import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/home_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  String _pin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _isBiometricsAvailable = false;
  bool _agreeToTerms = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }
  
  Future<void> _checkBiometrics() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAvailable = await authService.isBiometricsAvailable();
    
    setState(() {
      _isBiometricsAvailable = isAvailable;
    });
  }
  
  Future<void> _register() async {
    if (_isLoading) return;
    
    // Validate inputs
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
    
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the terms to continue';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Generate wallet
      await authService.generateWallet(_pin);
      
      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Secure Your Identity',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a PIN to protect your blockchain identity wallet',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                
                // Create PIN
                Text(
                  'Create PIN',
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
                  },
                  onChanged: (pin) {
                    setState(() {
                      _confirmPin = pin;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Biometrics option
                if (_isBiometricsAvailable)
                  CheckboxListTile(
                    value: true, // Always enable by default
                    onChanged: (_) {},
                    title: const Text('Enable Biometric Authentication'),
                    subtitle: const Text('Use fingerprint or face recognition for quick access'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppTheme.primaryColor,
                  ),
                
                // Terms checkbox
                CheckboxListTile(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  title: const Text('I agree to the Terms & Conditions'),
                  subtitle: const Text('By creating an account, you agree to our privacy policy and terms of service.'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryColor,
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
                
                // Register button
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
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