import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/dashboard_screen.dart';

const demoOperatorAtSign = '@lyra6dj01_sp';
const starterPackUrl = 'https://my.atsign.com/starterpack_app';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _openStarterPack() async {
    await launchUrl(
      Uri.parse(starterPackUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IoT Lighthouse',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Atsign-powered visibility and protection for telecom LTE gateways, POS terminals, smart meters, and field sensors.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(
                                operatorAtSign: demoOperatorAtSign,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in as @lyra6dj01_sp'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openStarterPack,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Get Starter Pack Atsigns'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _DemoAccountCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountCard extends StatelessWidget {
  const _DemoAccountCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demo tenant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Operator Atsign: @lyra6dj01_sp'),
            const Text('Protection service: @lyra6dj02_sp'),
            const Text('Threat monitor: @lyra6dj03_sp'),
            const SizedBox(height: 8),
            const Text(
              'For the MVP video, sign-in is hardcoded so the demo can focus on importing telecom devices and assigning each one an Atsign identity.',
            ),
          ],
        ),
      ),
    );
  }
}
