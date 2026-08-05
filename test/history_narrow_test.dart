import 'package:daybook/domain/fakes.dart';
import 'package:daybook/features/entry/journal_screen.dart';
import 'package:daybook/features/history/history_pane.dart';
import 'package:daybook/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = InMemoryEntryRepository();
    await repo.saveBody(DateTime(2026, 8, 1), 'walked to the harbour');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryRepositoryProvider.overrideWithValue(repo),
          currentDayProvider.overrideWith((ref) => DateTime(2026, 8, 2)),
        ],
        child: const MaterialApp(home: JournalScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a wide window shows history alongside the entry',
      (tester) async {
    await pumpAt(tester, const Size(1400, 900));

    expect(find.byType(HistoryPane), findsOneWidget);
    expect(find.byTooltip('History'), findsNothing);
  });

  testWidgets('a narrow window hides the pane but keeps a way in',
      (tester) async {
    await pumpAt(tester, const Size(700, 900));

    expect(find.byType(HistoryPane), findsNothing);
    expect(find.byTooltip('History'), findsOneWidget);
  });

  testWidgets('the narrow-window control opens history', (tester) async {
    await pumpAt(tester, const Size(700, 900));

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryPane), findsOneWidget);
    expect(find.text('walked to the harbour'), findsOneWidget);
  });

  testWidgets('opening a day from narrow history returns to the entry',
      (tester) async {
    await pumpAt(tester, const Size(700, 900));

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HistoryRow));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryPane), findsNothing);
    expect(find.text('Saturday, 1 August 2026'), findsOneWidget);
  });
}
