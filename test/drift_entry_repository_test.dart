import 'package:daybook/data/database.dart';
import 'package:daybook/data/drift_entry_repository.dart';
import 'package:drift/native.dart';

import 'support/entry_repository_contract.dart';

void main() {
  late DaybookDatabase db;

  runEntryRepositoryContract(
    'drift',
    open: () async {
      db = DaybookDatabase(NativeDatabase.memory());
      return DriftEntryRepository(db);
    },
    close: () async => db.close(),
  );
}
