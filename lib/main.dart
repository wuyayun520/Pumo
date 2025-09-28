import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/pumo_theme.dart';
import 'constants/pumo_constants.dart';
import 'services/pumo_storage_service.dart';
import 'screens/pumo_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await PumoStorageService.init();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const PumoApp());
}

class PumoApp extends StatelessWidget {
  const PumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: PumoConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: PumoTheme.lightTheme,
      home: const PumoLoginScreen(), // Always start with login screen
    );
  }
}
