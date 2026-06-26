import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../services/at_auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AtAuthService();
  bool _busy = false;

  Future<void> _run(Future<void> Function(BuildContext context) action) async {
    setState(() => _busy = true);
    await action(context);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _AuthAction(
        icon: Icons.key,
        title: 'Login from Keychain',
        body: 'Use an Atsign already stored on this device.',
        onTap: () => _run(_auth.loginWithKeychain),
      ),
      _AuthAction(
        icon: Icons.add_circle_outline,
        title: 'Onboard a New Atsign',
        body: 'Use the registrar flow for a fresh Atsign.',
        onTap: () => _run(_auth.onboard),
      ),
      _AuthAction(
        icon: Icons.verified_user_outlined,
        title: 'APKAM Enrollment',
        body: 'Authorize this device from one already approved.',
        onTap: () => _run(_auth.loginWithApkam),
      ),
      _AuthAction(
        icon: Icons.upload_file,
        title: 'Login via .atKeys File',
        body: 'Choose an exported Atsign key file.',
        onTap: () => _run(_auth.loginWithAtKeysFile),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('IoT Protector')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose an authentication method',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (_busy) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 2 : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3.4,
                    children: actions.map((action) => _AuthCard(action)).toList(),
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

class _AuthAction {
  const _AuthAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
}

class _AuthCard extends StatelessWidget {
  const _AuthCard(this.action);

  final _AuthAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(action.icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(action.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
