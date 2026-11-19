import 'dart:async';
import 'dart:math' as math;

import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P02 waiting (Figma 10:69): a 70 x 38 Bloom bubble with three dots.
/// Static when the platform asks for reduced motion.
///
/// Model calls can take 10-60 s on the live demo, so after [slowAfter] a
/// short line says Bloom is still working (the request has its own timeout,
/// which turns into the error card with "Try again").
class TypingIndicator extends StatefulWidget {
  const new({this.slowAfter = defaultSlowAfter, super.key});

  static const defaultSlowAfter = Duration(seconds: 12);

  final Duration slowAfter;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  Timer? _slowTimer;
  var _slow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: BloomSpacing.sm,
    children: [
      Semantics(
        label: context.l10n.patientChatTyping,
        liveRegion: true,
        excludeSemantics: true,
        child: Container(
          width: 70,
          height: 38,
          decoration: BoxDecoration(
            color: BloomColors.bgSurface,
            border: Border.all(color: BloomColors.borderDefault),
            borderRadius: BorderRadius.circular(BloomRadius.lg),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [for (var i = 0; i < 3; i++) _dot(i)],
            ),
          ),
        ),
      ),
      if (_slow)
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.patientChatSlowReply,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );

  Widget _dot(int index) {
    // Without animation the dots fade left to right, as drawn in Figma.
    final double alpha;
    if (_controller.isAnimating) {
      final phase = (_controller.value - index / 3) % 1;
      alpha = 0.35 + 0.65 * (0.5 + 0.5 * math.cos(phase * 2 * math.pi));
    } else {
      alpha = 1 - index * 0.3;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: BloomColors.actionPrimary.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}
