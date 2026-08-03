/// Plain domain models. Deliberately free of any drift or platform-channel
/// types so the UI never depends on how data is stored or where it came from.
library;

/// Strips the time component so a day is comparable by value.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The `YYYY-MM-DD` key a day is stored under.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// One journal page. Exactly one per calendar day.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.day,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final DateTime day;
  final String body;
  final DateTime updatedAt;

  bool get isEmpty => body.trim().isEmpty;
}

/// A due item shown in the context strip. On Windows this store is the source
/// of truth and syncs with no OS task system; on iOS it is backed by EventKit
/// reminders.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.dueAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final DateTime? dueAt;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  bool isOverdueAt(DateTime day) {
    final due = dueAt;
    if (due == null || isComplete) return false;
    return dateOnly(due).isBefore(dateOnly(day));
  }
}

/// A read-only calendar event. Read-only is a v1 product decision, not a
/// limitation of any one platform.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.colorValue,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  /// ARGB colour of the owning calendar, when the platform exposes one.
  final int? colorValue;
}

enum CalendarPermission { granted, denied, notDetermined, unavailable }
