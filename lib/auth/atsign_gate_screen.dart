import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const starterPackUrl = 'https://my.atsign.com/starterpack_app';

class AtsignGateScreen extends StatelessWidget {
  const AtsignGateScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  Future<void> _openStarterPack(BuildContext context) async {
    final uri = Uri.parse(starterPackUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open https://my.atsign.com/starterpack_app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Using this app requires an Atsign.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'If you already have an Atsign, click "Continue."\n\n'
                    'Or, get free, temporary Atsigns via the Starter Pack:\n'
                    '1. Click "Get My Starter Pack" below or visit $starterPackUrl in your browser.\n'
                    '2. Enter your email address.\n'
                    '3. Verify your email with a one-time passcode.\n'
                    '4. Come back to the app and click "Continue."',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openStarterPack(context),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Get My Starter Pack'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
