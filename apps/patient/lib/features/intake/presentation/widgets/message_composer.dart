import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P02 composer (Figma 6:75): pill input + 44 px round send button.
/// [paused] greys both out (refused / model error). While [canSend] is false
/// the patient can keep typing but not send (waiting for Bloom).
class MessageComposer extends StatefulWidget {
  const new({
    required this.onSend,
    this.paused = false,
    this.canSend = true,
    super.key,
  });

  /// The server accepts 1-4000 characters.
  static const maxLength = 4000;

  final ValueChanged<String> onSend;
  final bool paused;
  final bool canSend;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _sendEnabled =>
      !widget.paused && widget.canSend && _controller.text.trim().isNotEmpty;

  void _send() {
    if (!_sendEnabled) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paused = widget.paused;
    final fill = paused ? BloomColors.bgSubtle : BloomColors.bgSurface;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(BloomRadius.full),
      borderSide: const BorderSide(color: BloomColors.borderDefault),
    );
    final sendEnabled = _sendEnabled;

    return Row(
      spacing: BloomSpacing.sm,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !paused,
            autofocus: true,
            maxLength: MessageComposer.maxLength,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _send(),
            style: BloomTextStyles.body,
            decoration: InputDecoration(
              hintText: paused
                  ? l10n.patientChatInputPaused
                  : l10n.patientChatInputHint,
              hintStyle: BloomTextStyles.body.copyWith(
                color: BloomColors.textSecondary,
              ),
              hintMaxLines: 1,
              counterText: '',
              filled: true,
              fillColor: fill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BloomSpacing.lg,
                vertical: BloomSpacing.md,
              ),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: BloomColors.borderBrand,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: sendEnabled,
          label: l10n.patientChatSend,
          excludeSemantics: true,
          child: Material(
            color: paused ? BloomColors.bgSubtle : BloomColors.actionPrimary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: sendEnabled ? _send : null,
              child: SizedBox.square(
                dimension: BloomSpacing.minTapTarget,
                child: Icon(
                  Icons.send_outlined,
                  size: 18,
                  color: paused
                      ? BloomColors.textPrimary
                      : BloomColors.textOnAction.withValues(
                          alpha: sendEnabled ? 1 : 0.6,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
