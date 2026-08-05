import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';
// Prefixed: drift generates its own `Entry` and `Task` data classes, which
// would otherwise collide with the domain models of the same name.
import 'database.dart' as db;

/// SQLite-backed [EntryRepository]. Rows never leave this file — callers get
/// domain models, so nothing above `lib/data/` depends on drift.
class DriftEntryRepository implements EntryRepository {
  DriftEntryRepository(this._db);

  final db.DaybookDatabase _db;
  static const _uuid = Uuid();

  /// Days whose body is empty or whitespace-only are not "written" days.
  static const _hasContent = CustomExpression<bool>("trim(body) <> ''");

  JournalEntry _toDomain(db.Entry row) => JournalEntry(
        id: row.id,
        day: DateTime.parse(row.day),
        body: row.body,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      );

  @override
  Future<JournalEntry?> entryFor(DateTime day) async {
    final row = await (_db.select(_db.entries)
          ..where((t) => t.day.equals(dayKey(day)) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<JournalEntry> saveBody(DateTime day, String body) async {
    final key = dayKey(day);
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await (_db.select(_db.entries)
          ..where((t) => t.day.equals(key)))
        .getSingleOrNull();

    if (existing == null) {
      final row = db.Entry(
        id: _uuid.v4(),
        day: key,
        body: body,
        createdAt: now,
        updatedAt: now,
      );
      await _db.into(_db.entries).insert(row);
      return _toDomain(row);
    }

    final updated = existing.copyWith(body: body, updatedAt: now);
    await _db.update(_db.entries).replace(updated);
    return _toDomain(updated);
  }

  @override
  Future<List<JournalEntry>> recent({int limit = 50, int offset = 0}) async {
    final query = _db.select(_db.entries)
      ..where((t) => t.deletedAt.isNull() & _hasContent)
      ..orderBy([(t) => OrderingTerm.desc(t.day)])
      ..limit(limit, offset: offset);
    return (await query.get()).map(_toDomain).toList();
  }

  @override
  Future<List<JournalEntry>> search(String query) async {
    if (query.isEmpty) return const [];
    final rows = _db.select(_db.entries)
      ..where((t) => t.deletedAt.isNull() & t.body.like('%$query%'))
      ..orderBy([(t) => OrderingTerm.desc(t.day)]);
    return (await rows.get()).map(_toDomain).toList();
  }
}
