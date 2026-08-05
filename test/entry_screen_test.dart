import 'package:daybook/domain/fakes.dart';
import 'package:daybook/features/entry/entry_screen.dart';
import 'package:daybook/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 8, 2);

  Future<InMemoryEntryRepository> pumpEntryScreen(WidgetTester tester,
      {InMemoryEntryRepository? repository}) async {
    final repo = repository ?? InMemoryEntryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [entryRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: EntryScreen(day: day)),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('shows the date of the day being written', (tester) async {
    await pumpEntryScreen(tester);
    expect(find.text('Sunday, 2 August 2026'), findsOneWidget);
  });

  testWidgets('an existing entry is loaded into the editor', (tester) async {
    final repo = InMemoryEntryRepository();
    await repo.saveBody(day, 'written earlier');

    await pumpEntryScreen(tester, repository: repo);

    expect(find.text('written earlier'), findsOneWidget);
  });

  testWidgets('typing does not save before the debounce elapses',
      (tester) async {
    final repo = await pumpEntryScreen(tester);

    await tester.enterText(find.byType(TextField), 'rained all afternoon');
    await tester.pump(const Duration(milliseconds: 100));

    expect(await repo.entryFor(day), isNull);

    // Let the pending debounce fire so the test leaves no dangling timer.
    await tester.pump(EntryScreen.autosaveDebounce);
    await tester.pumpAndSettle();
  });

  testWidgets('typing autosaves once the debounce elapses', (tester) async {
    final repo = await pumpEntryScreen(tester);

    await tester.enterText(find.byType(TextField), 'rained all afternoon');
    await tester.pump(EntryScreen.autosaveDebounce);
    await tester.pumpAndSettle();

    expect((await repo.entryFor(day))!.body, 'rained all afternoon');
  });

  testWidgets('keystrokes in quick succession save once, at the end',
      (tester) async {
    final repo = await pumpEntryScreen(tester);

    await tester.enterText(find.byType(TextField), 'rain');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'rained');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'rained all afternoon');
    await tester.pump(EntryScreen.autosaveDebounce);
    await tester.pumpAndSettle();

    expect((await repo.entryFor(day))!.body, 'rained all afternoon');
    expect((await repo.recent()).length, 1);
  });

  testWidgets('a quiet saved indicator appears after saving', (tester) async {
    await pumpEntryScreen(tester);

    expect(find.text('Saved'), findsNothing);

    await tester.enterText(find.byType(TextField), 'something');
    await tester.pump(EntryScreen.autosaveDebounce);
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('there is no save button', (tester) async {
    await pumpEntryScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Save'), findsNothing);
    expect(find.byIcon(Icons.save), findsNothing);
  });
}
