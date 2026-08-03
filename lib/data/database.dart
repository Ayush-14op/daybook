import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Every table carries a UUID [id], an [updatedAt] stamp and a nullable
/// [deletedAt] soft-delete marker. Sync ships in v1.1, but retrofitting these
/// three columns afterwards is a migration; adding them now is free.
/// See PLAN.md decision D3.

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()(); // YYYY-MM-DD
  TextColumn get body => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {day},
      ];
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Entries, Tasks])
class DaybookDatabase extends _$DaybookDatabase {
  DaybookDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'daybook'));

  @override
  int get schemaVersion => 1;
}
