import 'package:flutter/material.dart';

/// Paper and ink, not dashboard.
///
/// The writing area is the hero: a serif face, generous line height, and a
/// surface that reads as warm paper in light and as low-glare dusk in dark.
/// Chrome stays in a plain sans so it recedes.
class DaybookTheme {
  const DaybookTheme._();

  /// Bundled with Windows and substituted sensibly elsewhere, so no font
  /// download or licence question — see PLAN.md step 1.1's fence.
  static const serifFamily = 'Georgia';

  static const _paper = Color(0xFFFAF6EF);
  static const _paperInk = Color(0xFF2A2521);
  static const _dusk = Color(0xFF16130F);
  static const _duskInk = Color(0xFFE6DFD3);

  /// One quiet accent. Calendar-colour dots are meant to be the only real
  /// pops of colour in the app.
  static const _accent = Color(0xFF4F6D7A);

  static final ThemeData light = _build(
    brightness: Brightness.light,
    surface: _paper,
    onSurface: _paperInk,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    surface: _dusk,
    onSurface: _duskInk,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
    ).copyWith(surface: surface, onSurface: onSurface);

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: base.textTheme.copyWith(
        // bodyLarge is the writing surface.
        bodyLarge: TextStyle(
          fontFamily: serifFamily,
          fontSize: 18,
          height: 1.6,
          color: onSurface,
        ),
      ),
    );
  }
}
