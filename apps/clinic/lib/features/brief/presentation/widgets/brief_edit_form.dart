import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/features/brief/domain/brief_diff.dart';
import 'package:bloom_clinic/features/brief/presentation/widgets/brief_sections.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D02 Edit mode: every text field of the draft, editable. List fields take
/// one item per line. Saving sends `decision: edit` with the full brief; the
/// server keeps the AI draft as `original_brief`.
class BriefEditForm extends StatefulWidget {
  const new({
    required this.draft,
    required this.onSave,
    required this.onCancel,
    this.isSaving = false,
    super.key,
  });

  final Brief draft;
  final ValueChanged<Brief> onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  @override
  State<BriefEditForm> createState() => _BriefEditFormState();
}

class _BriefEditFormState extends State<BriefEditForm> {
  late final Map<BriefSection, TextEditingController> _fields = {
    for (final s in BriefSection.values)
      s: TextEditingController(text: sectionLines(widget.draft, s).join('\n')),
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() => widget.onSave(
    buildEditedBrief(
      draft: widget.draft,
      subjective: _fields[BriefSection.subjective]!.text,
      objective: _fields[BriefSection.objective]!.text,
      assessment: _fields[BriefSection.assessment]!.text,
      plan: _fields[BriefSection.plan]!.text,
      flags: _fields[BriefSection.flags]!.text,
      screenings: _fields[BriefSection.screenings]!.text,
      questions: _fields[BriefSection.questions]!.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClinicBanner(
          type: ClinicBannerType.draft,
          text: l10n.clinicEditingBanner,
        ),
        for (final s in BriefSection.values) ...[
          const SizedBox(height: BloomSpacing.lg),
          SectionCard(
            title: sectionTitle(l10n, s),
            children: [
              TextField(
                key: ValueKey('edit-${s.name}'),
                controller: _fields[s],
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: null,
                style: BloomTextStyles.bodySmall,
                decoration: InputDecoration(
                  isDense: true,
                  helperText: switch (s) {
                    BriefSection.flags ||
                    BriefSection.screenings ||
                    BriefSection.questions => l10n.clinicEditOnePerLine,
                    _ => null,
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: BloomSpacing.lg),
        Wrap(
          spacing: BloomSpacing.md,
          runSpacing: BloomSpacing.sm,
          children: [
            BloomButton(
              label: l10n.clinicSaveEdits,
              icon: Icons.check,
              isLoading: widget.isSaving,
              onPressed: _save,
            ),
            BloomButton.secondary(
              label: l10n.clinicCancel,
              onPressed: widget.isSaving ? null : widget.onCancel,
            ),
          ],
        ),
      ],
    );
  }
}
