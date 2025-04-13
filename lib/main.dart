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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive for secure local storage
  await Hive.initFlutter();
  
  // Open boxes for storing data
  await Hive.openBox('settings');
  await Hive.openBox('userCredentials');
  
  runApp(const SecureMeApp());
}

class SecureMeApp extends StatelessWidget {
  const SecureMeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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