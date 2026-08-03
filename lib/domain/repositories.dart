/// The only route from the UI to storage or platform code.
///
/// If a widget ever needs `Platform.isWindows` to work out what a repository
/// gave it, the abstraction has leaked and the fix belongs here, not in the UI.
library;

import 'models.dart';

abstract class EntryRepository {
  /// The entry for [day], or null if nothing has been written yet.
  Future<JournalEntry?> entryFor(DateTime day);

  /// Creates or updates the entry for [day]. Returns the saved entry.
  Future<JournalEntry> saveBody(DateTime day, String body);

  /// Entries with content, newest first.
  Future<List<JournalEntry>> recent({int limit = 50, int offset = 0});

  /// Entries whose body contains [query] (case-insensitive substring).
  Future<List<JournalEntry>> search(String query);
}

abstract class TaskRepository {
  /// Tasks due or overdue as of [day], including completed ones for that day
  /// so a just-ticked item does not vanish under the user's cursor.
  Future<List<Task>> dueBy(DateTime day);

  Future<Task> create(String title, {DateTime? dueAt});

  Future<void> setComplete(String taskId, {required bool complete});
}

abstract class CalendarRepository {
  /// Events occurring on [day], sorted by start time. Read-only in v1.
  Future<List<CalendarEvent>> eventsOn(DateTime day);

  /// Requests access if needed. The app must stay fully usable when this
  /// returns anything other than [CalendarPermission.granted].
  Future<CalendarPermission> ensurePermission();
}
