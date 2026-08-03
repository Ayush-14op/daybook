/// In-memory repository implementations.
///
/// These are the default wiring until each real implementation lands, and they
/// stay the implementation used by tests afterwards — see PLAN.md step 1.3.
library;

import 'package:uuid/uuid.dart';

import 'models.dart';
import 'repositories.dart';

const _uuid = Uuid();

class InMemoryEntryRepository implements EntryRepository {
  final Map<String, JournalEntry> _byDay = {};

  @override
  Future<JournalEntry?> entryFor(DateTime day) async => _byDay[dayKey(day)];

  @override
  Future<JournalEntry> saveBody(DateTime day, String body) async {
    final key = dayKey(day);
    final entry = JournalEntry(
      id: _byDay[key]?.id ?? _uuid.v4(),
      day: dateOnly(day),
      body: body,
      updatedAt: DateTime.now(),
    );
    _byDay[key] = entry;
    return entry;
  }

  @override
  Future<List<JournalEntry>> recent({int limit = 50, int offset = 0}) async {
    final withContent = _byDay.values.where((e) => !e.isEmpty).toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return withContent.skip(offset).take(limit).toList();
  }

  @override
  Future<List<JournalEntry>> search(String query) async {
    final needle = query.toLowerCase();
    if (needle.isEmpty) return const [];
    final matches = _byDay.values
        .where((e) => e.body.toLowerCase().contains(needle))
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return matches;
  }
}

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _byId = {};

  @override
  Future<List<Task>> dueBy(DateTime day) async {
    final cutoff = dateOnly(day);
    final due = _byId.values.where((t) {
      final dueAt = t.dueAt;
      if (dueAt == null) return false;
      return !dateOnly(dueAt).isAfter(cutoff);
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return due;
  }

  @override
  Future<Task> create(String title, {DateTime? dueAt}) async {
    final task = Task(id: _uuid.v4(), title: title, dueAt: dueAt);
    _byId[task.id] = task;
    return task;
  }

  @override
  Future<void> setComplete(String taskId, {required bool complete}) async {
    final existing = _byId[taskId];
    if (existing == null) return;
    _byId[taskId] = Task(
      id: existing.id,
      title: existing.title,
      dueAt: existing.dueAt,
      completedAt: complete ? DateTime.now() : null,
    );
  }
}

/// Returns nothing, successfully. Lets every screen be built and tested before
/// any platform channel exists.
class EmptyCalendarRepository implements CalendarRepository {
  const EmptyCalendarRepository();

  @override
  Future<List<CalendarEvent>> eventsOn(DateTime day) async => const [];

  @override
  Future<CalendarPermission> ensurePermission() async =>
      CalendarPermission.unavailable;
}
