import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/device_models.dart';
import 'app_theme.dart';

const _mono = 'monospace';

/// Responsive breakpoints and padding derived from window width.
abstract final class AppLayout {
  static double horizontalPadding(double width) {
    if (width >= 1600) return 72;
    if (width >= 1200) return 48;
    if (width >= 768) return 32;
    return 20;
  }

  static EdgeInsets pageInsets(double width) => EdgeInsets.fromLTRB(
        horizontalPadding(width),
        8,
        horizontalPadding(width),
        32,
      );

  static bool isCompact(double width) => width < 768;
  static bool isWide(double width) => width >= 1100;
  static bool isUltraWide(double width) => width >= 1400;

  static int gridColumns(double width, {int maxColumns = 3}) {
    if (width >= 1400) return maxColumns;
    if (width >= 900) return 2;
    return 1;
  }
}

/// Fills available window width with responsive side padding.
class AppWindow extends StatelessWidget {
  const AppWindow({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = padding ?? AppLayout.pageInsets(constraints.maxWidth);
        return Padding(
          padding: insets,
          child: SizedBox(
            width: constraints.maxWidth,
            child: child,
          ),
        );
      },
    );
  }
}

/// Stacks children in a column, or places them side-by-side past [breakpoint].
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.breakpoint,
    required this.children,
    this.gap = 24,
    this.flex = const [],
  });

  final double breakpoint;
  final List<Widget> children;
  final double gap;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint || children.length < 2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i += 1) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        final weights = flex.length == children.length
            ? flex
            : List.filled(children.length, 1);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i += 1) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(flex: weights[i], child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Thin spectral rule — signature accent across the product.
class AppAccentRule extends StatelessWidget {
  const AppAccentRule({super.key, this.height = 2});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        gradient: AppColors.accentGradient,
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              leading: leading,
              title: Text(title!),
              actions: actions,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: AppWindow(child: body),
            );
          },
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.accent = false,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final bool accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AppAccentRule(height: 2),
            ),
            const SizedBox(height: 20),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class OperatorChip extends StatelessWidget {
  const OperatorChip({super.key, required this.atSign});

  final String atSign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        atSign,
        style: const TextStyle(
          fontFamily: _mono,
          fontSize: 12,
          color: AppColors.text,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

enum AppStatusTone { active, idle, warning, muted }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final AppStatusTone tone;

  Color get _fg {
    switch (tone) {
      case AppStatusTone.active:
        return AppColors.white;
      case AppStatusTone.idle:
        return AppColors.white;
      case AppStatusTone.warning:
        return AppColors.white;
      case AppStatusTone.muted:
        return AppColors.black;
    }
  }

  Color get _bg {
    switch (tone) {
      case AppStatusTone.active:
        return AppColors.emerald;
      case AppStatusTone.idle:
        return AppColors.gray400;
      case AppStatusTone.warning:
        return AppColors.ruby;
      case AppStatusTone.muted:
        return AppColors.gray200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _bg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: _fg,
        ),
      ),
    );
  }
}

class MonoBlock extends StatelessWidget {
  const MonoBlock({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 12,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.gray600),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.gray800),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

AppStatusTone protectionTone(ProtectionState state) {
  switch (state) {
    case ProtectionState.enabled:
      return AppStatusTone.active;
    case ProtectionState.disabled:
      return AppStatusTone.idle;
    case ProtectionState.isolated:
      return AppStatusTone.warning;
  }
}

String protectionLabel(ProtectionState state) {
  switch (state) {
    case ProtectionState.enabled:
      return 'Protected';
    case ProtectionState.disabled:
      return 'Unprotected';
    case ProtectionState.isolated:
      return 'Isolated';
  }
}
