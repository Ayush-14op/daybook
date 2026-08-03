/// iOS implementations are deliberately unimplemented until a Mac is available
/// to build and debug against — see PLAN.md decision D2 and stage 7.
///
/// A throwing stub is honest. Speculative EventKit code that has never been
/// compiled would be a lie about what this project has actually verified, so
/// do not fill these in without a Mac in hand.
library;

import '../../domain/models.dart';
import '../../domain/repositories.dart';

const _reason = 'iOS support is gated on Mac access — see PLAN.md stage 7.';

class EventKitCalendarRepository implements CalendarRepository {
  const EventKitCalendarRepository();

  @override
  Future<List<CalendarEvent>> eventsOn(DateTime day) =>
      throw UnimplementedError(_reason);

  @override
  Future<CalendarPermission> ensurePermission() =>
      throw UnimplementedError(_reason);
}

class EventKitTaskRepository implements TaskRepository {
  const EventKitTaskRepository();

  @override
  Future<List<Task>> dueBy(DateTime day) => throw UnimplementedError(_reason);

  @override
  Future<Task> create(String title, {DateTime? dueAt}) =>
      throw UnimplementedError(_reason);

  @override
  Future<void> setComplete(String taskId, {required bool complete}) =>
      throw UnimplementedError(_reason);
}
