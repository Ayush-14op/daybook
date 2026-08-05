import 'package:daybook/domain/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/entry_repository_contract.dart';

void main() {
  runEntryRepositoryContract(
    'in-memory',
    open: () async => InMemoryEntryRepository(),
  );

  group('TaskRepository contract (in-memory)', () {
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
