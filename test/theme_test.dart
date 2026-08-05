import 'package:daybook/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daybook theme', () {
    test('provides a light and a dark theme', () {
      expect(DaybookTheme.light.brightness, Brightness.light);
      expect(DaybookTheme.dark.brightness, Brightness.dark);
    });

    test('the writing surface uses a serif face in both themes', () {
      for (final theme in [DaybookTheme.light, DaybookTheme.dark]) {
        expect(theme.textTheme.bodyLarge!.fontFamily, DaybookTheme.serifFamily);
      }
    });

    test('the writing surface has generous line height', () {
      for (final theme in [DaybookTheme.light, DaybookTheme.dark]) {
        expect(theme.textTheme.bodyLarge!.height, greaterThanOrEqualTo(1.5));
      }
    });

    test('light is warm paper, not clinical white', () {
      final surface = DaybookTheme.light.colorScheme.surface;
      // Warm means red channel leads blue; pure white or a cool grey fails.
      expect(surface.r, greaterThan(surface.b));
    });

    test('dark is low-glare, not pure black', () {
      final surface = DaybookTheme.dark.colorScheme.surface;
      expect(surface.computeLuminance(), greaterThan(0.0));
      expect(surface.computeLuminance(), lessThan(0.1));
    });
  });
}
