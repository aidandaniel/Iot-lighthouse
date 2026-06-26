import 'package:at_client/at_client.dart';
import 'package:flutter/material.dart';

import 'auth/atsign_gate_screen.dart';
import 'auth/welcome_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/at_auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IotProtectorApp());
}

class IotProtectorApp extends StatelessWidget {
  const IotProtectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Protector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const StartupRouter(),
    );
  }
}

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  final _auth = AtAuthService();
  bool _loading = true;
  bool _gateRequired = false;
  bool _gateConfirmed = false;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkFirstRunGate();
  }

  Future<void> _checkFirstRunGate() async {
    final existing = await _auth.getExistingAtSigns();
    final currentAtSign =
        AtClientManager.getInstance().atClient.getCurrentAtSign();
    if (!mounted) return;
    setState(() {
      _gateRequired = existing.isEmpty;
      _authenticated = currentAtSign != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authenticated) return const DashboardScreen();
    if (_gateRequired && !_gateConfirmed) {
      return AtsignGateScreen(
        onContinue: () => setState(() => _gateConfirmed = true),
      );
    }
    return const WelcomeScreen();
  }
}
