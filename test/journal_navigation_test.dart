import 'package:daybook/domain/fakes.dart';
import 'package:daybook/domain/models.dart';
import 'package:daybook/features/entry/entry_screen.dart';
import 'package:daybook/features/entry/journal_screen.dart';
import 'package:daybook/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aug2 = DateTime(2026, 8, 2);

  Future<InMemoryEntryRepository> pumpJournal(WidgetTester tester,
      {InMemoryEntryRepository? repository}) async {
    final repo = repository ?? InMemoryEntryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryRepositoryProvider.overrideWithValue(repo),
          currentDayProvider.overrideWith((ref) => aug2),
        ],
        child: const MaterialApp(home: JournalScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> pressCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the current day', (tester) async {
    await pumpJournal(tester);
    expect(find.text('Sunday, 2 August 2026'), findsOneWidget);
  });

  testWidgets('the next-day control moves forward one day', (tester) async {
    await pumpJournal(tester);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect(find.text('Monday, 3 August 2026'), findsOneWidget);
  });

  testWidgets('the previous-day control moves back one day', (tester) async {
    await pumpJournal(tester);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('Saturday, 1 August 2026'), findsOneWidget);
  });

  testWidgets('ctrl+arrow navigates between days', (tester) async {
    await pumpJournal(tester);

    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('Monday, 3 August 2026'), findsOneWidget);

    await pressCtrl(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('Sunday, 2 August 2026'), findsOneWidget);
  });

  testWidgets('ctrl+T jumps back to today', (tester) async {
    await pumpJournal(tester);

    await pressCtrl(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('Sunday, 2 August 2026'), findsNothing);

    await pressCtrl(tester, LogicalKeyboardKey.keyT);

    final today = dateOnly(DateTime.now());
    expect(find.text(_formatted(today)), findsOneWidget);
  });

  testWidgets('each day holds its own text', (tester) async {
    final repo = await pumpJournal(tester);

    await tester.enterText(find.byType(TextField), 'written on the second');
    await tester.pump(EntryScreen.autosaveDebounce);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect(find.text('written on the second'), findsNothing);
    expect(await repo.entryFor(DateTime(2026, 8, 3)), isNull);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('written on the second'), findsOneWidget);
  });

  testWidgets('navigating mid-debounce still saves to the day it was typed on',
      (tester) async {
    final repo = await pumpJournal(tester);

    await tester.enterText(find.byType(TextField), 'evening thoughts');
    // Leave before the debounce fires — the classic way to lose a sentence.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect((await repo.entryFor(aug2))?.body, 'evening thoughts');
    expect(await repo.entryFor(DateTime(2026, 8, 3)), isNull);
  });
}

String _formatted(DateTime d) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}
