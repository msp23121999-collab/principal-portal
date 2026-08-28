import 'package:flutter/material.dart';
import 'package:erp_unified/modules/parent_portal/theme/app_theme.dart';
import 'package:erp_unified/modules/parent_portal/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: Firebase initialization is available via Firebase.initializeApp()
  // if you add firebase_core, but it's optional for this demo version

  runApp(const ParentPortalApp());
}

class ParentPortalApp extends StatelessWidget {
  const ParentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KSRCE ERP - Parent Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
