import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum ChatAuthor { patient, bloom }

/// Figma component "ChatBubble". Bloom's messages sit left on a brand tint;
/// the patient's sit right on the primary colour. [isOptional] adds the
/// "Optional question" marker above a Bloom question.
class ChatBubble extends StatelessWidget {
  const new({
    required this.text,
    required this.author,
    this.isOptional = false,
    this.optionalLabel = 'Optional question',
    super.key,
  });

  final String text;
  final ChatAuthor author;
  final bool isOptional;
  final String optionalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = BloomTokens.of(context);
    final isBloom = author == ChatAuthor.bloom;
    const radius = Radius.circular(BloomRadius.lg);
    const tail = Radius.circular(BloomSpacing.xs);

    final speaker = isBloom ? 'Bloom' : 'You';
    final semantic = [
      if (isOptional) optionalLabel,
      '$speaker said: $text',
    ].join('. ');

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: Align(
        alignment: isBloom ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isBloom ? tokens.brandSubtle : theme.colorScheme.primary,
              border: isBloom ? Border.all(color: tokens.brandMuted) : null,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isBloom ? tail : radius,
                bottomRight: isBloom ? radius : tail,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BloomSpacing.lg,
                vertical: BloomSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOptional) ...[
                    Text(
                      optionalLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: BloomSpacing.xs),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isBloom
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
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
