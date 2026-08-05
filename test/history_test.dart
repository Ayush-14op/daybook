import 'package:daybook/domain/fakes.dart';
import 'package:daybook/features/history/history_pane.dart';
import 'package:daybook/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aug2 = DateTime(2026, 8, 2);

  Future<void> pumpHistory(
    WidgetTester tester,
    InMemoryEntryRepository repo, {
    ValueChanged<DateTime>? onOpenDay,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryRepositoryProvider.overrideWithValue(repo),
          currentDayProvider.overrideWith((ref) => aug2),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HistoryPane(onOpenDay: onOpenDay ?? (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says so when nothing has been written yet', (tester) async {
    await pumpHistory(tester, InMemoryEntryRepository());

    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('lists written days newest first, with a preview',
      (tester) async {
    final repo = InMemoryEntryRepository();
    await repo.saveBody(DateTime(2026, 8, 1), 'the first of the month');
    await repo.saveBody(DateTime(2026, 8, 3), 'the third of the month');

    await pumpHistory(tester, repo);

    expect(find.text('Sat, 1 Aug 2026'), findsOneWidget);
    expect(find.text('Mon, 3 Aug 2026'), findsOneWidget);
    expect(find.text('the first of the month'), findsOneWidget);

    final rows = tester.widgetList(find.byType(HistoryRow)).toList();
    expect(rows.length, 2);
    expect((rows.first as HistoryRow).entry.body, 'the third of the month');
  });

  testWidgets('blank days are not listed', (tester) async {
    final repo = InMemoryEntryRepository();
    await repo.saveBody(aug2, '   ');

    await pumpHistory(tester, repo);

    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('a long entry is previewed on one line, not in full',
      (tester) async {
    final repo = InMemoryEntryRepository();
    final long = 'word ' * 200;
    await repo.saveBody(aug2, long);

    await pumpHistory(tester, repo);

    final preview = tester.widget<Text>(find.byKey(const ValueKey('preview')));
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
  });

  testWidgets('tapping a row opens that day', (tester) async {
    final repo = InMemoryEntryRepository();
    await repo.saveBody(DateTime(2026, 8, 1), 'the first of the month');

    DateTime? opened;
    await pumpHistory(tester, repo, onOpenDay: (d) => opened = d);

    await tester.tap(find.byType(HistoryRow));
    await tester.pumpAndSettle();

    expect(opened, DateTime(2026, 8, 1));
  });

  testWidgets('a newly written entry appears without a restart',
      (tester) async {
    final repo = InMemoryEntryRepository();
    await pumpHistory(tester, repo);
    expect(find.text('No entries yet'), findsOneWidget);

    await repo.saveBody(aug2, 'written just now');
    // The pane rebuilds when the entries provider is invalidated after a save.
    final element = tester.element(find.byType(HistoryPane));
    ProviderScope.containerOf(element).invalidate(recentEntriesProvider);
    await tester.pumpAndSettle();

    expect(find.text('written just now'), findsOneWidget);
  });
}
