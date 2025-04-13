import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:secureme_id/screens/splash_screen.dart';
import 'package:secureme_id/services/auth_service.dart';
import 'package:secureme_id/services/blockchain_service.dart';
import 'package:secureme_id/services/document_service.dart';
import 'package:secureme_id/services/encryption_service.dart';
import 'package:secureme_id/services/ipfs_service.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'package:secureme_id/utils/security_utils.dart';
import 'dart:async';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better user experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable error reporting zone to catch and handle errors
  runZonedGuarded(() async {
    // Initialize security utilities
    final securityUtils = SecurityUtils();

    // Security check for compromised device
    final isCompromised = await securityUtils.isDeviceCompromised();
    final isTampered = securityUtils.isAppTampered();

    // Initialize Hive for secure local storage
    await Hive.initFlutter();

    // Open boxes for storing data
    await Hive.openBox('settings');
    await Hive.openBox('userCredentials');

    // Run the app
    runApp(SecureMeApp(
      isCompromised: isCompromised,
      isTampered: isTampered,
    ));
  }, (error, stack) {
    // Global error handler
    // In a production app, this would report to a crash reporting service
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class SecureMeApp extends StatelessWidget {
  final bool isCompromised;
  final bool isTampered;

  const SecureMeApp({
    Key? key,
    this.isCompromised = false,
    this.isTampered = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If device is compromised, show security warning
    if (isCompromised || isTampered) {
      return MaterialApp(
        title: 'SecureMeID',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SecurityWarningScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => EncryptionService()),
        ChangeNotifierProvider(create: (_) => BlockchainService()),
        ChangeNotifierProvider(create: (_) => IPFSService()),
        ChangeNotifierProvider(create: (_) => DocumentService()),
      ],
      child: MaterialApp(
        title: 'SecureMeID',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

/// Screen shown when security issues are detected
class SecurityWarningScreen extends StatelessWidget {
  const SecurityWarningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111827)
          : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security icon
              Icon(
                Icons.security,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 32),

              // Warning title
              Text(
                'Security Risk Detected',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Warning description
              Text(
                'This app contains sensitive information and cannot run on a compromised device. Please use a secure device to access your identity wallet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Exit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Exit the app
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Exit App'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
