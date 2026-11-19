/// Bloom strings (ARB, `en`). Regenerate with `flutter gen-l10n` in this
/// package after editing `lib/src/arb/app_en.arb`.
library;

import 'package:flutter/widgets.dart';
import 'package:l10n/src/generated/bloom_localizations.dart';

export 'src/generated/bloom_localizations.dart';

extension BloomLocalizationsX on BuildContext {
  /// Shorthand for `BloomLocalizations.of(context)`.
  BloomLocalizations get l10n => BloomLocalizations.of(this);
}
