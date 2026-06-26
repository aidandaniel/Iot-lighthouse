import 'package:flutter/material.dart';

import 'auth/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IotLighthouseApp());
}

class IotLighthouseApp extends StatelessWidget {
  const IotLighthouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Lighthouse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WelcomeScreen(),
    );
  }
}
