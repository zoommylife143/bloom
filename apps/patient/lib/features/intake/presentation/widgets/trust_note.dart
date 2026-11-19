import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P02 trust note (Figma 6:82). Says "Confidential inference" only in
/// private mode; dev mode says plainly that it is not confidential.
class TrustNote extends StatelessWidget {
  const new({required this.mode, super.key});

  final RouteMode? mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final private = mode == RouteMode.private;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: BloomSpacing.xs,
      children: [
        ExcludeSemantics(
          child: Icon(
            private ? Icons.lock_outline : Icons.science_outlined,
            size: 14,
            color: private
                ? BloomColors.statusVerified
                : BloomColors.statusWarning,
          ),
        ),
        Flexible(
          child: Text(
            private ? l10n.patientChatModePrivate : l10n.patientChatModeDev,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
