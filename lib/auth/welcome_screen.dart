import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

const demoOperatorAtSign = '@lyra6dj01_sp';

const _mono = 'monospace';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _scroll = ScrollController();
  final _authKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _authenticate() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const DashboardScreen(operatorAtSign: demoOperatorAtSign),
      ),
    );
  }

  void _scrollToAuth() {
    final ctx = _authKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 720;
        final ultra = AppLayout.isUltraWide(width);
        final theme = Theme.of(context);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              child: AppWindow(
                padding: EdgeInsets.fromLTRB(
                  AppLayout.horizontalPadding(width),
                  24,
                  AppLayout.horizontalPadding(width),
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Nav(onSignIn: _scrollToAuth),
                    SizedBox(
                        height: ultra
                            ? 88
                            : wide
                                ? 72
                                : 48),
                    if (ultra)
                      ResponsiveColumns(
                        breakpoint: 1200,
                        gap: 48,
                        flex: const [6, 5],
                        children: [
                          _HeroCopy(
                            wide: wide,
                            theme: theme,
                            onPrimary: _scrollToAuth,
                          ),
                          const _StatsGrid(),
                        ],
                      )
                    else ...[
                      const AppAccentRule(height: 3),
                      const SizedBox(height: 32),
                      _HeroCopy(
                        wide: wide,
                        theme: theme,
                        onPrimary: _scrollToAuth,
                      ),
                      SizedBox(height: wide ? 80 : 56),
                      const _StatsGrid(),
                    ],
                    SizedBox(height: wide ? 80 : 56),
                    Text('How it works', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'From fleet import to per-device protection.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    const _HowItWorksPanel(),
                    SizedBox(height: wide ? 80 : 56),
                    _ProtocolRow(onPrimary: _scrollToAuth),
                    SizedBox(height: wide ? 80 : 56),
                    KeyedSubtree(
                      key: _authKey,
                      child: _AuthPanel(onAuthenticate: _authenticate),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'IoT Lighthouse · Powered by atSign',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
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

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.wide,
    required this.theme,
    required this.onPrimary,
  });

  final bool wide;
  final ThemeData theme;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!AppLayout.isUltraWide(MediaQuery.sizeOf(context).width))
          const AppAccentRule(height: 3),
        if (!AppLayout.isUltraWide(MediaQuery.sizeOf(context).width))
          const SizedBox(height: 32),
        Text(
          'Secure every\nsignaling device.',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: wide ? 52 : 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Assign an atSign to any IoT device. '
          'Encrypt your data transfer end to end.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: onPrimary,
              child: const Text('Open console'),
            ),
            OutlinedButton(
              onPressed: onPrimary,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mist,
          ),
        ),
        const SizedBox(width: 10),
        Text('IoT Lighthouse', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        TextButton(onPressed: onSignIn, child: const Text('Sign in')),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  static const _stats = [
    _Stat(
      '8.8B',
      'Wireless connections',
      'The total number of wireless connections globally. Nearly 6 billion people rely on these networks daily.',
    ),
    _Stat(
      '\$7.6T',
      'Economic impact',
      'The mobile industry\'s contribution to global GDP. A systemic signaling failure threatens the core of the digital economy.',
    ),
    _Stat(
      '1,000+',
      'Trusted operators',
      'SS7 and Diameter networks are accessed by over a thousand operators worldwide, relying on an outdated model of inherent trust.',
    ),
    _Stat(
      '100%',
      'Legacy SS7 surface',
      'Every mobile network globally still relies on SS7 for international roaming, SMS routing, and 2G/3G fallback, with phase-out not expected until 2030-2035.',
    ),
  ];

  static const _shades = [
    AppColors.black,
    AppColors.gray800,
    AppColors.gray700,
    AppColors.gray800,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final cols = AppLayout.gridColumns(c.maxWidth, maxColumns: 4);
        const gap = 12.0;
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(_stats.length, (i) {
            final s = _stats[i];
            return SizedBox(
              width: itemW,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: _shades[i],
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(s.detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.value, this.label, this.detail);
  final String value;
  final String label;
  final String detail;
}

class _HowItWorksPanel extends StatelessWidget {
  const _HowItWorksPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            'IoT Lighthouse gives any IoT device an Atsign identity, then encrypts your data transfer end to end before it leaves the device or gateway. The operator can see the device, the payload stays private in transit, and only the authorized service or account can decrypt it.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({required this.onPrimary});

  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fleet coverage', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Import the Diameter and SS7 demo fleet, assign atSign identities, and prove encrypted telemetry from device to company in one flow.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPrimary,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Open console'),
          ),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.onAuthenticate,
  });

  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppAccentRule(height: 2),
          const SizedBox(height: 24),
          Text('Operator access', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Sign in with your atSign to manage devices and telemetry.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  demoOperatorAtSign,
                  style: TextStyle(
                    fontFamily: _mono,
                    fontSize: 14,
                    color: AppColors.text,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAuthenticate,
              child: const Text('Authenticate'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Activation options appear after demo sign-in.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
