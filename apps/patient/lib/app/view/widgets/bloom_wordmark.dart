import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Figma "Brand" lockup: sparkle icon + "Bloom" in Heading, brand colour.
// TODO(figma): the logo is an unnamed vector in Figma (26:6, 6:5). This uses
// the closest Material icon until the SVG is exported.
class BloomWordmark extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: context.l10n.patientBrandName,
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
          context.l10n.patientBrandName,
          style: BloomTextStyles.heading.copyWith(color: BloomColors.textBrand),
        ),
      ],
    ),
  );
}
