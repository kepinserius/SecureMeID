import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/auth/recovery_screen.dart';
import 'package:secureme_id/screens/home_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _pin = '';
  String _errorMessage = '';
  bool _isBiometricsAvailable = false;
  
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
    
    // If biometrics are available, try to authenticate automatically
    if (isAvailable) {
      _authenticateWithBiometrics();
    }
  }
  
  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginWithBiometrics();
      
      if (success) {
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = 'Biometric authentication failed. Please try again or use PIN.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _login() async {
    if (_isLoading || _pin.length < 6) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(_pin);
      
      if (success) {
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
  
  void _navigateToRecovery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecoveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Welcome Back',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your secure identity wallet',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                
                // Pin input
                PinInput(
                  onCompleted: (pin) {
                    setState(() {
                      _pin = pin;
                    });
                    _login();
                  },
                  onChanged: (pin) {
                    setState(() {
                      _pin = pin;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Biometric login button
                if (_isBiometricsAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Login with Biometrics'),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Recovery option
                TextButton(
                  onPressed: _navigateToRecovery,
                  child: Text(
                    'Forgot PIN? Recover Account',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.primaryColor,
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