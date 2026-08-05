import 'package:daybook/domain/fakes.dart';
import 'package:daybook/features/history/entry_preview.dart';
import 'package:daybook/features/history/history_pane.dart';
import 'package:daybook/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('previewAround', () {
    test('without a query it previews from the start', () {
      expect(previewAround('the quick brown fox', ''), 'the quick brown fox');
    });

    test('collapses whitespace so newlines do not blank the row', () {
      expect(previewAround('\n\n  the   fox\nran', ''), 'the fox ran');
    });

    test('centres the window on the match, not the start of the body', () {
      final body = '${'a' * 200} needle ${'b' * 200}';

      final preview = previewAround(body, 'needle', radius: 10);

      expect(preview, contains('needle'));
      expect(preview.length, lessThan(body.length));
    });

    test('marks that text was trimmed from either end', () {
      final body = '${'a' * 200} needle ${'b' * 200}';

      final preview = previewAround(body, 'needle', radius: 10);

      expect(preview.startsWith('…'), isTrue);
      expect(preview.endsWith('…'), isTrue);
    });

    test('a match near the start is not falsely marked as trimmed', () {
      expect(previewAround('needle in there', 'needle', radius: 10),
          startsWith('needle'));
    });

    test('a query that is not present falls back to the start', () {
      expect(previewAround('the quick brown fox', 'zebra'),
          'the quick brown fox');
    });
  });

  group('search in the history pane', () {
    Future<InMemoryEntryRepository> pumpPane(WidgetTester tester) async {
      final repo = InMemoryEntryRepository();
      await repo.saveBody(DateTime(2026, 8, 1), 'rained all afternoon');
      await repo.saveBody(DateTime(2026, 8, 2), 'walked to the harbour');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [entryRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(body: HistoryPane(onOpenDay: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('shows every written day before anything is typed',
        (tester) async {
      await pumpPane(tester);
      expect(find.byType(HistoryRow), findsNWidgets(2));
    });

    testWidgets('a query narrows the list to matches', (tester) async {
      await pumpPane(tester);

      await tester.enterText(find.byType(TextField), 'harbour');
      await tester.pumpAndSettle();

      expect(find.byType(HistoryRow), findsOneWidget);
      expect(find.text('walked to the harbour'), findsOneWidget);
    });

    testWidgets('matching ignores case', (tester) async {
      await pumpPane(tester);

      await tester.enterText(find.byType(TextField), 'HARBOUR');
      await tester.pumpAndSettle();

      expect(find.byType(HistoryRow), findsOneWidget);
    });

    testWidgets('a query with no matches says so', (tester) async {
      await pumpPane(tester);

      await tester.enterText(find.byType(TextField), 'penguins');
      await tester.pumpAndSettle();

      expect(find.byType(HistoryRow), findsNothing);
      expect(find.text('No matching entries'), findsOneWidget);
    });

    testWidgets('clearing the query restores the full list', (tester) async {
      await pumpPane(tester);

      await tester.enterText(find.byType(TextField), 'harbour');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.byType(HistoryRow), findsNWidgets(2));
    });
  });
}
