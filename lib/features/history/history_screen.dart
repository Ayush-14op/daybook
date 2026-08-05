import 'package:flutter/material.dart';

import 'history_pane.dart';

/// History as its own screen, for windows too narrow to give it a column.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.onOpenDay});

  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: HistoryPane(onOpenDay: onOpenDay),
    );
  }
}
