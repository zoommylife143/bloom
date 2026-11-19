import 'package:bloom_ui/bloom_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A01 role tile (Figma 26:20 / 26:27): brand-subtle bg, brand border,
/// radius md, 24 px icon + Title and Body Small. The whole tile is the
/// action.
class RoleTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Null disables the tile.
  final VoidCallback? onTap;

  /// Shows a spinner in place of the icon.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(BloomRadius.md);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: BloomColors.bgBrandSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: BloomColors.borderBrand),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BloomSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BloomSpacing.lg),
              child: Row(
                spacing: BloomSpacing.md,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(3),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(icon, size: 24, color: BloomColors.textBrand),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: BloomSpacing.xs,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: BloomColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
