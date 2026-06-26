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
                    SizedBox(height: ultra ? 88 : wide ? 72 : 48),
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
                    const _StepsList(),
                    SizedBox(height: wide ? 80 : 56),
                    const _ProtocolRow(),
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
          'Assign an atSign to each Diameter and SS7 node. '
          'Encrypt telemetry end to end — no central plaintext store.',
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
            color: AppColors.gray900,
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
    _Stat('60%', 'Breaches from unpatched firmware'),
    _Stat('\$330K', 'Average incident cost'),
    _Stat('89%', 'Rise in AI-driven attacks'),
    _Stat('50%', 'Fewer attacks with updated firmware'),
  ];

  static const _shades = [
    AppColors.gray900,
    AppColors.gray800,
    AppColors.gray700,
    AppColors.gray600,
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
                    Text(s.label, style: theme.textTheme.bodyMedium),
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
  const _Stat(this.value, this.label);
  final String value;
  final String label;
}

class _StepsList extends StatelessWidget {
  const _StepsList();

  static const _steps = [
    'Telecom company signs up and onboarded to the console',
    'Import devices via .txt file or manual entry',
    'Device records stored as encrypted AtKeys',
    'Toggle atSign protection per device',
    'View live telemetry and traceability map',
  ];

  static const _shades = [
    AppColors.gray900,
    AppColors.gray800,
    AppColors.gray700,
    AppColors.gray600,
    AppColors.gray500,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = AppLayout.gridColumns(c.maxWidth, maxColumns: 5);
        if (cols > 1) {
          const gap = 10.0;
          final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(_steps.length, (i) {
              return SizedBox(
                width: itemW,
                child: _StepTile(index: i + 1, text: _steps[i], color: _shades[i]),
              );
            }),
          );
        }
        return Column(
          children: List.generate(
            _steps.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StepTile(index: i + 1, text: _steps[i], color: _shades[i]),
            ),
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.text,
    required this.color,
  });

  final int index;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: TextStyle(
              fontFamily: _mono,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final sideBySide = c.maxWidth >= 720;
          if (!sideBySide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProtocolBar(
                  label: 'Diameter · 4G/LTE',
                  pct: 0.60,
                  color: AppColors.gray800,
                ),
                const SizedBox(height: 16),
                const _ProtocolBar(
                  label: 'SS7 · 2G/3G',
                  pct: 0.20,
                  color: AppColors.gray600,
                ),
                const SizedBox(height: 16),
                Text(
                  '65% faster breach breakout. Encrypted atSign channels '
                  'close the gap legacy protocols leave open.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            );
          }
          return Row(
            children: [
              const Expanded(
                child: _ProtocolBar(
                  label: 'Diameter · 4G/LTE',
                  pct: 0.60,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: _ProtocolBar(
                  label: 'SS7 · 2G/3G',
                  pct: 0.20,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet coverage', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      '65% faster breach breakout. Encrypted atSign channels '
                      'close the gap legacy protocols leave open.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProtocolBar extends StatelessWidget {
  const _ProtocolBar({
    required this.label,
    required this.pct,
    required this.color,
  });

  final String label;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                  ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.gray300,
            color: color,
          ),
        ),
      ],
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
