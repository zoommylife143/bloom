import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/features/brief/domain/brief_diff.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

String sectionTitle(BloomLocalizations l10n, BriefSection s) => switch (s) {
  BriefSection.subjective => l10n.clinicSectionSubjective,
  BriefSection.objective => l10n.clinicSectionObjective,
  BriefSection.assessment => l10n.clinicSectionAssessment,
  BriefSection.plan => l10n.clinicSectionPlan,
  BriefSection.flags => l10n.clinicSectionFlags,
  BriefSection.screenings => l10n.clinicSectionScreenings,
  BriefSection.questions => l10n.clinicSectionQuestions,
};

/// True for the server's placeholder line when no guideline was retrieved.
bool isNoGuidelineLine(ScreeningLine line) =>
    line.sourceUrl == null &&
    line.text.trim().toLowerCase().startsWith('no guideline retrieved');

/// The brief's section cards (D02). Draft sections carry a "Draft, needs
/// your review" marker until a physician decides; edited sections say how
/// many lines the physician changed.
class BriefSections extends StatelessWidget {
  const new({required this.bundle, super.key});

  final BriefBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brief = bundle.brief;
    final review = bundle.provenance.reviewStatus;
    final isDraft = review == ReviewStatus.draft;
    final dimmed = review == ReviewStatus.rejected;
    final original = bundle.edited ? bundle.originalBrief : null;

    Widget? marker(BriefSection s) {
      if (isDraft) {
        return Text(
          l10n.clinicSectionDraftMarker,
          style: BloomTextStyles.caption.copyWith(color: BloomColors.textBrand),
        );
      }
      return null;
    }

    Widget editedNote(BriefSection s) {
      final n = changedLines(original, brief, s);
      if (n == 0) return const SizedBox.shrink();
      return Text(
        l10n.clinicEditedLines(n),
        style: BloomTextStyles.caption.copyWith(color: BloomColors.textBrand),
      );
    }

    Widget card(BriefSection s, List<Widget> lines) => SectionCard(
      title: sectionTitle(l10n, s),
      trailing: marker(s),
      dimmed: dimmed,
      children: [
        ...lines,
        if (changedLines(original, brief, s) > 0) editedNote(s),
      ],
    );

    List<Widget> textLines(BriefSection s, {bool bullet = false}) {
      final lines = sectionLines(brief, s);
      if (lines.isEmpty) {
        return [
          Text(
            l10n.clinicSectionEmpty,
            style: BloomTextStyles.bodySmall.copyWith(
              color: BloomColors.textSecondary,
            ),
          ),
        ];
      }
      return [for (final l in lines) SectionLine(l, bullet: bullet)];
    }

    final titles = {
      for (final e in bundle.evidence)
        if (e.title case final t? when t.isNotEmpty) e.url: t,
    };
    final cited = <String>{
      for (final l in brief.screeningsPossiblyDue) ?l.sourceUrl,
    }.toList();

    final screenings = <Widget>[
      for (final line in brief.screeningsPossiblyDue)
        if (isNoGuidelineLine(line))
          SectionLine(l10n.clinicNoGuidelineCopy)
        else ...[
          SectionLine(line.text),
          if (line.sourceUrl == null) const CitationLink.none(),
        ],
      if (brief.screeningsPossiblyDue.isEmpty)
        SectionLine(l10n.clinicNoGuidelineCopy),
      if (cited.isNotEmpty)
        Wrap(
          spacing: BloomSpacing.lg,
          children: [
            for (final url in cited)
              CitationLink(title: titles[url] ?? hostOf(url), url: url),
          ],
        ),
    ];

    final children = <Widget>[
      card(BriefSection.subjective, textLines(BriefSection.subjective)),
      card(BriefSection.objective, textLines(BriefSection.objective)),
      card(BriefSection.assessment, textLines(BriefSection.assessment)),
      card(BriefSection.plan, textLines(BriefSection.plan)),
      if (brief.flags.isNotEmpty || (original?.flags.isNotEmpty ?? false))
        card(BriefSection.flags, textLines(BriefSection.flags, bullet: true)),
      card(BriefSection.screenings, screenings),
      card(
        BriefSection.questions,
        textLines(BriefSection.questions, bullet: true),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: BloomSpacing.lg),
          children[i],
        ],
      ],
    );
  }
}

/// D02 generating: section titles with skeleton bars.
class BriefSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget bar(double max) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: const SkeletonBar(width: double.infinity),
    );
    final sections = [
      BriefSection.subjective,
      BriefSection.objective,
      BriefSection.screenings,
      BriefSection.questions,
    ];
    return Semantics(
      label: l10n.clinicGeneratingBanner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, s) in sections.indexed) ...[
            if (i > 0) const SizedBox(height: BloomSpacing.lg),
            SectionCard(
              title: sectionTitle(l10n, s),
              children: [bar(520), bar(380)],
            ),
          ],
        ],
      ),
    );
  }
}
