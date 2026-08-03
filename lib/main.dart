import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'providers.dart';

void main() {
  runApp(
    ProviderScope(
      // Real drift-backed repositories replace these in stage 1.3.
      overrides: inMemoryOverrides(),
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
      home: const TodayScreen(),
    );
  }
}

/// Stage 0 placeholder: proves the app boots and knows what day it is.
/// The real entry screen lands in stage 1.2.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    return Scaffold(
      body: Center(
        child: Text(today, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
