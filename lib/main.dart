import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/drift_entry_repository.dart';
import 'domain/fakes.dart';
import 'features/entry/journal_screen.dart';
import 'providers.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DaybookDatabase();

  runApp(
    ProviderScope(
      overrides: [
        entryRepositoryProvider
            .overrideWithValue(DriftEntryRepository(database)),
        // Tasks move to a drift-backed store in stage 3.
        taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
      ],
      child: const DaybookApp(),
    ),
  );
}

class DaybookApp extends StatelessWidget {
  const DaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daybook',
      debugShowCheckedModeBanner: false,
      theme: DaybookTheme.light,
      darkTheme: DaybookTheme.dark,
      themeMode: ThemeMode.system,
      home: const JournalScreen(),
    );
  }
}
