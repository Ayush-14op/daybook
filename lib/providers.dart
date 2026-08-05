import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/fakes.dart';
import 'domain/models.dart';
import 'domain/repositories.dart';

/// The day currently on screen. "Today" is just where you start.
final currentDayProvider =
    StateProvider<DateTime>((ref) => dateOnly(DateTime.now()));

/// Days with something written on them, newest first. Invalidated after a
/// save so the history list reflects what was just typed.
final recentEntriesProvider = FutureProvider<List<JournalEntry>>(
  (ref) => ref.watch(entryRepositoryProvider).recent(),
);

/// Repository wiring. Each provider throws until it is overridden at app
/// startup (or in a test), so a missing override fails loudly instead of
/// silently reading from the wrong store.
///
/// Tests override these with the in-memory fakes; `main()` overrides them with
/// whatever real implementation exists on this platform today.

final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => throw UnimplementedError('entryRepositoryProvider not overridden'),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => throw UnimplementedError('taskRepositoryProvider not overridden'),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => const EmptyCalendarRepository(),
);

/// The overrides used until the drift-backed repositories land in stage 1.3.
List<Override> inMemoryOverrides() => [
      entryRepositoryProvider.overrideWithValue(InMemoryEntryRepository()),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
    ];
