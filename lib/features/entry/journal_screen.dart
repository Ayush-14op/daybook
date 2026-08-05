import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'entry_screen.dart';

/// Owns which day is on screen and the keyboard shortcuts for moving between
/// days. The page itself stays a plain function of the day it was given.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);

    void goTo(DateTime target) =>
        ref.read(currentDayProvider.notifier).state = dateOnly(target);

    // Built by field rather than Duration arithmetic so daylight-saving
    // transitions cannot land us on the same day twice or skip one.
    void shift(int days) =>
        goTo(DateTime(day.year, day.month, day.day + days));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            () => shift(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            () => shift(1),
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () =>
            goTo(DateTime.now()),
      },
      child: EntryScreen(
        // Keyed by day so each page gets its own editor state rather than
        // inheriting the previous day's text.
        key: ValueKey(dayKey(day)),
        day: day,
        onNavigate: goTo,
      ),
    );
  }
}
