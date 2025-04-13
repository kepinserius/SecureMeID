import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/auth/recovery_screen.dart';
import 'package:secureme_id/screens/home_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/widgets/pin_input.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _pin = '';
  String _errorMessage = '';
  bool _isBiometricsAvailable = false;
  bool _showBiometricAnimation = false;

  // Brute force protection
  int _failedAttempts = 0;
  Timer? _lockoutTimer;
  int _lockoutSeconds = 0;
  bool _isLockedOut = false;

  // Animation controller
  late AnimationController _animationController;
  bool _showLogo = true;

  // Available biometric types
  List<BiometricType> _availableBiometricTypes = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkBiometrics();

    // Delayed logo animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAvailable = await authService.isBiometricsAvailable();
    final availableTypes = await authService.getAvailableBiometrics();

    setState(() {
      _isBiometricsAvailable = isAvailable;
      _availableBiometricTypes = availableTypes;
    });

    // Don't auto-authenticate anymore - better to ask user explicitly
  }

  // Sets a lockout timer if too many failed attempts
  void _checkAndSetLockout() {
    _failedAttempts++;

    if (_failedAttempts >= 3) {
      // Exponential backoff: 30s, 1m, 2m, 5m, 10m, 30m
      final lockoutTimes = [30, 60, 120, 300, 600, 1800];
      final lockoutIndex =
          (_failedAttempts - 3).clamp(0, lockoutTimes.length - 1);
      _lockoutSeconds = lockoutTimes[lockoutIndex];

      setState(() {
        _isLockedOut = true;
      });

      _lockoutTimer?.cancel();
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _lockoutSeconds--;
          if (_lockoutSeconds <= 0) {
            _isLockedOut = false;
            timer.cancel();
          }
        });
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading || _isLockedOut) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _showBiometricAnimation = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginWithBiometrics();

      if (success) {
        // Reset failed attempts on success
        _failedAttempts = 0;
        _navigateToHome();
      } else {
        _checkAndSetLockout();
        setState(() {
          _errorMessage =
              'Biometric authentication failed. Please try again or use PIN.';
          _isLoading = false;
          _showBiometricAnimation = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error occurred. Please try again.';
        _isLoading = false;
        _showBiometricAnimation = false;
      });
    }
  }

  Future<void> _login() async {
    if (_isLoading || _pin.length < 6 || _isLockedOut) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(_pin);

      if (success) {
        // Reset failed attempts on success
        _failedAttempts = 0;
        _navigateToHome();
      } else {
        _checkAndSetLockout();
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login error occurred. Please try again.';
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

  Widget _buildLockoutMessage() {
    final minutes = _lockoutSeconds ~/ 60;
    final seconds = _lockoutSeconds % 60;
    final timeString = minutes > 0
        ? '$minutes min ${seconds > 0 ? '$seconds sec' : ''}'
        : '$seconds seconds';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Account Temporarily Locked',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Too many failed login attempts. Please wait $timeString before trying again.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    final isBrightness = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBrightness ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 14,
            color: isBrightness ? const Color(0xFF4B5563) : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            'Secure Login',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isBrightness ? const Color(0xFF4B5563) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Get appropriate biometric icon
    IconData biometricIcon = Icons.fingerprint;
    String biometricName = 'Biometrics';

    if (_availableBiometricTypes.contains(BiometricType.face)) {
      biometricIcon = Icons.face;
      biometricName = 'Face ID';
    } else if (_availableBiometricTypes.contains(BiometricType.fingerprint)) {
      biometricIcon = Icons.fingerprint;
      biometricName = 'Fingerprint';
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF111827)
                      : Colors.white,
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header spacing
                    SizedBox(height: size.height * 0.06),

                    // Logo with animation
                    AnimatedOpacity(
                      opacity: _showLogo ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        )),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Security badge
                    _buildSecurityBadge(),

                    // Title section
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access your secure identity wallet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? AppTheme.textSecondaryColor
                            : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Lockout message
                    if (_isLockedOut) _buildLockoutMessage(),

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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppTheme.errorColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading && !_showBiometricAnimation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        onPressed: (_isLoading || _isLockedOut) ? null : _login,
                        label: const Text('Login with PIN'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biometric login button
                    if (_isBiometricsAvailable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _isLockedOut)
                              ? null
                              : _authenticateWithBiometrics,
                          icon: _showBiometricAnimation
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor),
                                  ),
                                )
                              : Icon(biometricIcon),
                          label: Text('Login with $biometricName'),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Recovery option
                    TextButton.icon(
                      onPressed: (_isLoading || _isLockedOut)
                          ? null
                          : _navigateToRecovery,
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Forgot PIN? Recover Account'),
                    ),

                    // Extra spacing at bottom
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
