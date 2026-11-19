import 'package:bloom_patient/app/view/widgets/content_column.dart';
import 'package:bloom_patient/app/view/widgets/patient_button.dart';
import 'package:bloom_patient/features/done/presentation/pages/done_page.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a `tel:` link. Injectable for tests.
typedef TelLauncher = Future<void> Function(Uri uri);

/// P03 Urgent care (Figma 6:125). Renders the server's fixed
/// `UrgentMessage` (no model wrote it): title, body, optional support line,
/// then one button per action in the server's order (988 first for R5).
/// The chat is locked: the router never returns to P02 from here.
class UrgentPage extends StatelessWidget {
  const new({this.launchTel, super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'P03';

  /// Path inside the app. Public URL: `/intake/urgent` (base href
  /// `/intake/`).
  static const path = '/urgent';

  final TelLauncher? launchTel;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IntakeBloc>().state;
    final message = state is IntakeUrgent
        ? state.message
        : IntakeBloc.fallbackUrgent;
    return Scaffold(
      backgroundColor: BloomColors.statusCriticalSubtle,
      body: SafeArea(
        child: ContentColumn(
          child: UrgentView(
            message: message,
            launchTel: launchTel ?? _launch,
            onAcknowledge: () => context.goNamed(DonePage.screenId),
          ),
        ),
      ),
    );
  }

  static Future<void> _launch(Uri uri) async {
    await launchUrl(uri);
  }
}

/// The P03 content. Visual order = reading order: title, body, support,
/// then the actions (first action is the most urgent).
class UrgentView extends StatefulWidget {
  const new({
    required this.message,
    required this.launchTel,
    required this.onAcknowledge,
    super.key,
  });

  final UrgentMessage message;
  final TelLauncher launchTel;
  final VoidCallback onAcknowledge;

  @override
  State<UrgentView> createState() => _UrgentViewState();
}

class _UrgentViewState extends State<UrgentView> {
  @override
  void initState() {
    super.initState();
    // Screen-reader first: announce the title as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.message.title,
        Directionality.of(context),
      ).ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final message = widget.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: BloomSpacing.lg,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: BloomSpacing.lg,
              children: [
                const ExcludeSemantics(child: _AlertBadge()),
                Semantics(
                  header: true,
                  child: Text(
                    message.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: BloomColors.statusCritical,
                    ),
                  ),
                ),
                Semantics(
                  child: Text(message.body, style: theme.textTheme.bodyLarge),
                ),
                if (message.support case final support?)
                  Semantics(
                    child: Text(support, style: theme.textTheme.bodyMedium),
                  ),
                Semantics(
                  child: Text(
                    l10n.patientUrgentStopped,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: BloomSpacing.sm,
          children: [
            for (final (i, action) in message.actions.indexed)
              Semantics(
                child: PatientButton(
                  key: ValueKey('urgent-action-$i'),
                  label: action.label,
                  expand: true,
                  style: i == 0
                      ? PatientButtonStyle.critical
                      : PatientButtonStyle.secondary,
                  onPressed: () => widget.launchTel(Uri.parse(action.tel)),
                ),
              ),
            Semantics(
              child: PatientButton(
                label: l10n.patientUrgentAcknowledge,
                expand: true,
                style: PatientButtonStyle.ghost,
                onPressed: widget.onAcknowledge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: const BoxDecoration(
      color: BloomColors.bgSurface,
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.warning_amber_rounded,
      size: 32,
      color: BloomColors.statusCritical,
    ),
  );
}
