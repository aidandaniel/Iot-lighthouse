import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

const starterPackUrl = 'https://my.atsign.com/starterpack_app';

class AtsignGateScreen extends StatelessWidget {
  const AtsignGateScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  Future<void> _openStarterPack(BuildContext context) async {
    final uri = Uri.parse(starterPackUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open https://my.atsign.com/starterpack_app'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Scaffold(
          body: SafeArea(
            child: AppWindow(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalPadding(width),
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppAccentRule(height: 3),
                    const SizedBox(height: 32),
                    Text(
                      'An atSign is required',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'IoT Lighthouse uses atSign identities for operators and devices. '
                      'If you already have one, continue to sign in.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    ResponsiveColumns(
                      breakpoint: 900,
                      gap: 32,
                      flex: const [1, 1],
                      children: [
                        AppPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Get a Starter Pack',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              const _Step(
                                n: '1',
                                text: 'Open the Starter Pack link below',
                              ),
                              const _Step(
                                n: '2',
                                text: 'Enter and verify your email',
                              ),
                              const _Step(
                                n: '3',
                                text: 'Return here and tap Continue',
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: () => _openStarterPack(context),
                              child: const Text('Get Starter Pack'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: onContinue,
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
