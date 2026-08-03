import 'package:daybook/domain/fakes.dart';
import 'package:daybook/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryRepository contract', () {
    late InMemoryEntryRepository repo;
    final day = DateTime(2026, 8, 2);

    setUp(() => repo = InMemoryEntryRepository());

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
      expect(await (repo.entryFor(day)).then((e) => e!.body), 'draft, revised');
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

    test('search matches body text case-insensitively', () async {
      await repo.saveBody(day, 'Rained all afternoon');

      expect((await repo.search('RAINED')).single.body, 'Rained all afternoon');
      expect(await repo.search('snow'), isEmpty);
      expect(await repo.search(''), isEmpty);
    });
  });

  group('TaskRepository contract', () {
    late InMemoryTaskRepository repo;
    final today = DateTime(2026, 8, 2);

    setUp(() => repo = InMemoryTaskRepository());

    test('dueBy includes overdue and today, excludes future', () async {
      await repo.create('yesterday', dueAt: DateTime(2026, 8, 1));
      await repo.create('today', dueAt: today);
      await repo.create('tomorrow', dueAt: DateTime(2026, 8, 3));
      await repo.create('someday'); // no due date

      final due = await repo.dueBy(today);

      expect(due.map((t) => t.title), ['yesterday', 'today']);
    });

    test('completion persists and is reversible', () async {
      final task = await repo.create('post the letter', dueAt: today);

      await repo.setComplete(task.id, complete: true);
      expect((await repo.dueBy(today)).single.isComplete, isTrue);

      await repo.setComplete(task.id, complete: false);
      expect((await repo.dueBy(today)).single.isComplete, isFalse);
    });

    test('a completed task is no longer overdue', () async {
      final task = await repo.create('late thing', dueAt: DateTime(2026, 8, 1));
      expect((await repo.dueBy(today)).single.isOverdueAt(today), isTrue);

      await repo.setComplete(task.id, complete: true);
      expect((await repo.dueBy(today)).single.isOverdueAt(today), isFalse);
    });
  });
}
