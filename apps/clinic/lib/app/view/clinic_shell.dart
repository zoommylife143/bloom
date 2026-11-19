import 'package:bloom_clinic/app/cubit/mode_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

enum ClinicNav { queue, audit, demo }

/// Shared clinic shell (Figma sidebar 7:3): brand, navigation and the Mode
/// card. Below [sidebarBreakpoint] the sidebar becomes a compact top bar
/// (D02 tablet hides the sidebar).
class ClinicShell extends StatelessWidget {
  const new({required this.location, required this.child, super.key});

  static const sidebarBreakpoint = 1100.0;
  static const sidebarWidth = 248.0;

  final String location;
  final Widget child;

  static ClinicNav navFor(String location) {
    if (location.startsWith('/audit')) return ClinicNav.audit;
    if (location.startsWith('/demo')) return ClinicNav.demo;
    return ClinicNav.queue;
  }

  @override
  Widget build(BuildContext context) {
    final active = navFor(location);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sidebarBreakpoint) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(active: active),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          body: Column(
            children: [
              _TopBar(active: active),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bloom',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          size: 24,
          color: BloomColors.textBrand,
        ),
        const SizedBox(width: BloomSpacing.sm),
        Text(
          'Bloom',
          style: BloomTextStyles.heading.copyWith(color: BloomColors.textBrand),
        ),
      ],
    ),
  );
}

({String label, IconData icon, String path}) _navData(
  BuildContext context,
  ClinicNav nav,
) {
  final l10n = context.l10n;
  return switch (nav) {
    ClinicNav.queue => (
      label: l10n.clinicNavQueue,
      icon: Icons.people_outline,
      path: '/',
    ),
    ClinicNav.audit => (
      label: l10n.clinicNavAudit,
      icon: Icons.format_list_bulleted,
      path: '/audit',
    ),
    ClinicNav.demo => (
      label: l10n.clinicNavDemo,
      icon: Icons.play_arrow_outlined,
      path: '/demo',
    ),
  };
}

class _Sidebar extends StatelessWidget {
  const new({required this.active});

  final ClinicNav active;

  @override
  Widget build(BuildContext context) => Container(
    width: ClinicShell.sidebarWidth,
    decoration: const BoxDecoration(
      color: BloomColors.bgSurface,
      border: Border(right: BorderSide(color: BloomColors.borderDefault)),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: BloomSpacing.lg,
      vertical: BloomSpacing.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: _Brand()),
        const SizedBox(height: BloomSpacing.lg),
        for (final nav in ClinicNav.values) ...[
          _NavItem(nav: nav, active: nav == active),
          const SizedBox(height: BloomSpacing.xs),
        ],
        const Spacer(),
        const ModeCard(),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const new({required this.nav, required this.active, this.expand = true});

  final ClinicNav nav;
  final bool active;

  /// Fill the available width (sidebar). The top bar puts items in a
  /// horizontal scroll view, which has unbounded width, so there the item
  /// hugs its label instead.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final data = _navData(context, nav);
    final color = active ? BloomColors.textBrand : BloomColors.textSecondary;
    final label = Text(
      data.label,
      style: BloomTextStyles.label.copyWith(color: color),
    );
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? BloomColors.bgBrandMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(BloomRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(BloomRadius.md),
          onTap: () => context.go(data.path),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BloomSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BloomSpacing.md),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(data.icon, size: 20, color: color),
                  const SizedBox(width: BloomSpacing.md),
                  if (expand) Expanded(child: label) else label,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({required this.active});

  final ClinicNav active;

  /// Below this width the nav moves to its own row under the brand and
  /// Mode card (phones).
  static const twoRowBreakpoint = 720.0;
  static const modeCardWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final nav = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final nav in ClinicNav.values) ...[
            _NavItem(nav: nav, active: nav == active, expand: false),
            const SizedBox(width: BloomSpacing.xs),
          ],
        ],
      ),
    );
    return Container(
      decoration: const BoxDecoration(
        color: BloomColors.bgSurface,
        border: Border(bottom: BorderSide(color: BloomColors.borderDefault)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BloomSpacing.lg,
        vertical: BloomSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= twoRowBreakpoint) {
              return Row(
                children: [
                  const _Brand(),
                  const SizedBox(width: BloomSpacing.lg),
                  Expanded(child: nav),
                  const SizedBox(
                    width: modeCardWidth,
                    child: ModeCard(compact: true),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _Brand(),
                    const SizedBox(width: BloomSpacing.lg),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: modeCardWidth,
                          ),
                          child: const ModeCard(compact: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BloomSpacing.xs),
                nav,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Sidebar Mode card: what the server says about routing, from
/// `GET /api/healthz`. Private: confidential route only, fails closed. Dev:
/// the GLM route is zero data retention (operator-declared), never
/// "confidential".
class ModeCard extends StatelessWidget {
  const new({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = BloomTokens.of(context);
    final mode = context.watch<ModeCubit>().state;
    final (title, note, bg, fg, icon) = switch (mode) {
      RouteMode.private => (
        l10n.clinicModePrivateTitle,
        l10n.clinicModePrivateNote,
        tokens.verifiedSubtle,
        tokens.verified,
        Icons.verified_user_outlined,
      ),
      RouteMode.dev => (
        l10n.clinicModeDevTitle,
        l10n.clinicModeDevNote,
        tokens.warningSubtle,
        tokens.warning,
        Icons.science_outlined,
      ),
      null => (
        l10n.clinicModeUnknownTitle,
        l10n.clinicModeUnknownNote,
        BloomColors.bgSubtle,
        tokens.textSecondary,
        Icons.help_outline,
      ),
    };
    return Semantics(
      container: true,
      label: '$title. $note',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(compact ? BloomSpacing.sm : BloomSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BloomRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: BloomSpacing.xs),
                Flexible(
                  child: Text(
                    title,
                    style: BloomTextStyles.label.copyWith(color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BloomSpacing.xs),
            Text(
              note,
              style: BloomTextStyles.caption,
              maxLines: compact ? 1 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
            ),
          ],
        ),
      ),
    );
  }
}
