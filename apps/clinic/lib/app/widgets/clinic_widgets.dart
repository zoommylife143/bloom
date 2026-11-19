import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Figma Banner types (component set 4:56).
enum ClinicBannerType { demo, urgent, draft, verified }

/// Figma "Banner" as drawn on the clinic screens: 18 px icon plus a Label in
/// the type colour. Icon + text so meaning never depends on colour alone.
class ClinicBanner extends StatelessWidget {
  const new({
    required this.type,
    required this.text,
    this.hug = false,
    super.key,
  });

  final ClinicBannerType type;
  final String text;

  /// Hug the text instead of filling the width (D01 Demo banner).
  final bool hug;

  static IconData iconFor(ClinicBannerType type) => switch (type) {
    ClinicBannerType.demo => Icons.info_outline,
    ClinicBannerType.urgent => Icons.warning_amber_rounded,
    ClinicBannerType.draft => Icons.auto_awesome_outlined,
    ClinicBannerType.verified => Icons.verified_user_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = BloomTokens.of(context);
    final (Color bg, Color fg) = switch (type) {
      ClinicBannerType.demo => (tokens.warningSubtle, tokens.warning),
      ClinicBannerType.urgent => (tokens.criticalSubtle, tokens.critical),
      ClinicBannerType.draft => (tokens.brandSubtle, BloomColors.textBrand),
      ClinicBannerType.verified => (tokens.verifiedSubtle, tokens.verified),
    };
    final label = Text(text, style: BloomTextStyles.label.copyWith(color: fg));
    return Semantics(
      container: true,
      liveRegion: type == ClinicBannerType.urgent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BloomRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BloomSpacing.lg,
            vertical: BloomSpacing.md,
          ),
          child: Row(
            mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(iconFor(type), size: 18, color: fg),
              const SizedBox(width: BloomSpacing.sm),
              if (hug) Flexible(child: label) else Expanded(child: label),
            ],
          ),
        ),
      ),
    );
  }
}

/// White card with 1 px default border and radius lg (Figma section cards,
/// table, panels).
class ClinicCard extends StatelessWidget {
  const new({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: BloomSpacing.xl,
      vertical: BloomSpacing.lg,
    ),
    this.color = BloomColors.bgSurface,
    this.width,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: BloomColors.borderDefault),
      borderRadius: BorderRadius.circular(BloomRadius.lg),
    ),
    padding: padding,
    child: child,
  );
}

/// Brief / red-flag section card: Overline title in brand colour, then Body
/// Small lines.
class SectionCard extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    this.trailing,
    this.dimmed = false,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  /// Rejected briefs render at 50 % opacity (D02 rejected).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final card = ClinicCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap, not Row: a long trailing marker moves under the title on
          // narrow screens instead of overflowing.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: BloomSpacing.sm,
            runSpacing: BloomSpacing.xs,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title.toUpperCase(),
                  style: BloomTextStyles.overline.copyWith(
                    color: BloomColors.textBrand,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: BloomSpacing.sm),
            child,
          ],
        ],
      ),
    );
    return dimmed ? Opacity(opacity: 0.5, child: card) : card;
  }
}

/// One Body Small line inside a [SectionCard].
class SectionLine extends StatelessWidget {
  const new(this.text, {this.bullet = false, super.key});

  final String text;
  final bool bullet;

  @override
  Widget build(BuildContext context) =>
      Text(bullet ? '• $text' : text, style: BloomTextStyles.bodySmall);
}

/// Loading placeholder bar (Figma skeleton, radius 6).
class SkeletonBar extends StatelessWidget {
  const new({required this.width, this.height = 14, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: BloomColors.bgSubtle,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

/// D01 / D05 page header: Display title, Body Small subtitle, optional
/// action on the right.
class PageHeader extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.trailing,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Heading + Caption (D02, D06) instead of Display + Body Small.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: compact
                      ? BloomTextStyles.heading
                      : BloomTextStyles.display,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: BloomSpacing.xs),
                Text(
                  sub,
                  style: compact
                      ? BloomTextStyles.caption
                      : BloomTextStyles.bodySmall.copyWith(
                          color: BloomColors.textSecondary,
                        ),
                ),
              ],
            ],
          ),
        ),
        if (trailing case final trailing?) ...[
          const SizedBox(width: BloomSpacing.lg),
          trailing,
        ],
      ],
    );
  }
}

/// Scrollable page body with the Figma main padding (32).
class PageBody extends StatelessWidget {
  const new({required this.children, this.controller, super.key});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    padding: const EdgeInsets.all(BloomSpacing.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: BloomSpacing.xl),
          children[i],
        ],
      ],
    ),
  );
}

/// Plain-language message for a failure. Never shows raw server bodies.
String failureMessage(BloomLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.clinicErrorNetwork,
      RouteRefusedFailure() => l10n.clinicRefusedMessage,
      LockedFailure() => l10n.clinicErrorLocked,
      NotFoundFailure() => l10n.clinicErrorNotFound,
      ServerFailure(statusCode: 401) => l10n.clinicErrorSignedOut,
      ServerFailure(statusCode: 403) => l10n.clinicErrorForbidden,
      ServerFailure() => l10n.clinicErrorServer,
    };

/// True when the failure means the demo token is missing or expired.
bool isAuthFailure(AppFailure failure) =>
    failure is ServerFailure &&
    (failure.statusCode == 401 || failure.statusCode == 403);

/// Error state with a retry button, or "Sign in again" when the token
/// expired.
class FailureView extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = isAuthFailure(failure);
    return ClinicCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClinicBanner(
            type: ClinicBannerType.urgent,
            text: failureMessage(l10n, failure),
          ),
          const SizedBox(height: BloomSpacing.md),
          if (auth)
            BloomButton.secondary(
              label: l10n.clinicSignInAgain,
              onPressed: () => context.read<AuthCubit>().signOut(),
            )
          else
            BloomButton.secondary(
              label: l10n.clinicRetry,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
