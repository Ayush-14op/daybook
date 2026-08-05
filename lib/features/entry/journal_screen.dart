import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import '../history/history_pane.dart';
import '../history/history_screen.dart';
import 'entry_screen.dart';

/// Owns which day is on screen, the keyboard shortcuts for moving between
/// days, and how the history list is presented at this window size.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  /// Above this width the history list earns a permanent column; below it, the
  /// writing area needs the whole window and history becomes its own screen.
  static const historyPaneBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);

    void goTo(DateTime target) {
      ref.read(currentDayProvider.notifier).state = dateOnly(target);
      // The page being left may have flushed a pending save on the way out.
      ref.invalidate(recentEntriesProvider);
    }

    // Built by field rather than Duration arithmetic so daylight-saving
    // transitions cannot land us on the same day twice or skip one.
    void shift(int days) =>
        goTo(DateTime(day.year, day.month, day.day + days));

    // Keyed by day so each page gets its own editor state rather than
    // inheriting the previous day's text.
    EntryScreen page({VoidCallback? onOpenHistory}) => EntryScreen(
          key: ValueKey(dayKey(day)),
          day: day,
          onNavigate: goTo,
          onOpenHistory: onOpenHistory,
        );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            () => shift(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            () => shift(1),
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () =>
            goTo(DateTime.now()),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < historyPaneBreakpoint) {
            return page(
              onOpenHistory: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => HistoryScreen(
                    onOpenDay: (target) {
                      goTo(target);
                      Navigator.of(routeContext).pop();
                    },
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 280, child: HistoryPane(onOpenDay: goTo)),
                const VerticalDivider(width: 1),
                Expanded(child: page()),
              ],
            ),
          );
        },
      ),
    );
  }
}
