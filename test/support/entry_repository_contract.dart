/// One suite, run against every [EntryRepository] implementation.
///
/// The in-memory fake and the drift-backed store must be indistinguishable to
/// the UI — that is the whole point of the interface. Running identical
/// expectations against both is what keeps that true.
library;

import 'package:daybook/domain/models.dart';
import 'package:daybook/domain/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void runEntryRepositoryContract(
  String implementation, {
  required Future<EntryRepository> Function() open,
  Future<void> Function()? close,
}) {
  group('EntryRepository contract ($implementation)', () {
    late EntryRepository repo;
    final day = DateTime(2026, 8, 2);

    setUp(() async => repo = await open());
    tearDown(() async => close?.call());

    test('a day with nothing written has no entry', () async {
      expect(await repo.entryFor(day), isNull);
    });

    test('saved text reads back for the same day', () async {
      await repo.saveBody(day, 'first light on the roofs');
      final entry = await repo.entryFor(day);

      expect(entry, isNotNull);
      expect(entry!.body, 'first light on the roofs');
      expect(dayKey(entry.day), '2026-08-02');
    });

    test('saving again keeps the same id, so sync has a stable key', () async {
      final first = await repo.saveBody(day, 'draft');
      final second = await repo.saveBody(day, 'draft, revised');

      expect(second.id, first.id);
      expect((await repo.entryFor(day))!.body, 'draft, revised');
    });

    test('the time of day does not create a second entry', () async {
      await repo.saveBody(DateTime(2026, 8, 2, 9, 15), 'morning');
      await repo.saveBody(DateTime(2026, 8, 2, 23, 40), 'night');

      expect((await repo.recent()).length, 1);
    });

    test('recent returns days with content, newest first', () async {
      await repo.saveBody(DateTime(2026, 8, 1), 'older');
      await repo.saveBody(DateTime(2026, 8, 3), 'newer');
      await repo.saveBody(DateTime(2026, 8, 2), '   '); // whitespace only

      final recent = await repo.recent();

      expect(recent.map((e) => e.body), ['newer', 'older']);
    });

    test('recent honours limit and offset', () async {
      await repo.saveBody(DateTime(2026, 8, 1), 'oldest');
      await repo.saveBody(DateTime(2026, 8, 2), 'middle');
      await repo.saveBody(DateTime(2026, 8, 3), 'newest');

      expect((await repo.recent(limit: 2)).map((e) => e.body),
          ['newest', 'middle']);
      expect((await repo.recent(limit: 2, offset: 1)).map((e) => e.body),
          ['middle', 'oldest']);
    });

    test('search matches body text case-insensitively', () async {
      await repo.saveBody(day, 'Rained all afternoon');

      expect((await repo.search('RAINED')).single.body, 'Rained all afternoon');
      expect(await repo.search('snow'), isEmpty);
      expect(await repo.search(''), isEmpty);
    });

    test('updatedAt advances when the body changes', () async {
      final first = await repo.saveBody(day, 'one');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await repo.saveBody(day, 'two');

      expect(second.updatedAt.isBefore(first.updatedAt), isFalse);
    });
  });
}
