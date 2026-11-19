import 'package:bloom_clinic/features/dev_gallery/presentation/cubit/gallery_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Dev page with every bloom_ui component and state, for visual checks
/// against Figma. Synthetic content only.
class GalleryPage extends StatelessWidget {
  const new({super.key});

  static const routeName = 'DEV_GALLERY';
  static const path = '/dev/gallery';

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => GalleryCubit(), child: const GalleryView());
}

class GalleryView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: BloomSpacing.xl),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: BloomSpacing.md),
              Wrap(
                spacing: BloomSpacing.sm,
                runSpacing: BloomSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.screenGallery)),
      body: ListView(
        padding: const EdgeInsets.all(BloomSpacing.xl),
        children: [
          section('Button', [
            BloomButton(label: 'Primary', onPressed: () {}),
            BloomButton.secondary(label: 'Secondary', onPressed: () {}),
            BloomButton.text(label: 'Text', onPressed: () {}),
            BloomButton(label: 'Loading', isLoading: true, onPressed: () {}),
            const BloomButton(label: 'Disabled', onPressed: null),
          ]),
          section('StatusChip', [
            for (final status in BloomStatus.values) StatusChip(status: status),
          ]),
          section('ChatBubble', const [
            ChatBubble(
              text: 'What brings you in today?',
              author: ChatAuthor.bloom,
            ),
            ChatBubble(
              text: 'Pelvic pain for three days.',
              author: ChatAuthor.patient,
            ),
            ChatBubble(
              text: 'When was your last cervical screening?',
              author: ChatAuthor.bloom,
              isOptional: true,
            ),
          ]),
          section('QuickReply', [
            QuickReply(
              options: const ['Yes', 'No', 'Not sure'],
              onSelected: (_) {},
            ),
          ]),
          section('Banner', [
            const BloomBanner.demo(),
            const BloomBanner.routeRefused(),
            BloomBanner.modelError(onAction: () {}),
            const BloomBanner(message: 'Info banner'),
            const BloomBanner(
              message: 'Verified banner',
              variant: BloomBannerVariant.verified,
            ),
          ]),
          section('CitationLink', [
            CitationLink(
              title: 'Cervical cancer screening',
              url: 'https://www.uspreventiveservicestaskforce.org/',
              onOpen: (_) {},
            ),
            const CitationLink.none(),
          ]),
          section('TrustRow', const [
            TrustRow(
              label: 'Route',
              value: 'ZDR (operator-declared)',
              status: TrustRowStatus.verified,
            ),
            TrustRow(
              label: 'Attestation',
              value: 'Not returned',
              status: TrustRowStatus.notExposed,
            ),
            TrustRow(
              label: 'Negative test',
              value: 'confidential',
              status: TrustRowStatus.refused,
            ),
            TrustRow(
              label: 'Mode',
              value: 'dev',
              status: TrustRowStatus.devWarning,
            ),
          ]),
          section('DecisionBar', [
            BlocBuilder<GalleryCubit, BloomDecision?>(
              builder: (context, decision) {
                final cubit = context.read<GalleryCubit>();
                return DecisionBar(
                  decision: decision,
                  onConfirm: () => cubit.decide(BloomDecision.confirmed),
                  onEdit: () => cubit.decide(BloomDecision.edited),
                  onReject: () => cubit.decide(BloomDecision.rejected),
                );
              },
            ),
            BloomButton.text(
              label: 'Reset',
              onPressed: context.read<GalleryCubit>().reset,
            ),
          ]),
        ],
      ),
    );
  }
}
