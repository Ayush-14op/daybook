import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';

/// Reverse-chronological list of days that have something written on them.
class HistoryPane extends ConsumerWidget {
  const HistoryPane({super.key, required this.onOpenDay});

  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recentEntriesProvider);
    final theme = Theme.of(context);

    return entries.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load entries', style: theme.textTheme.bodySmall),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No entries yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: list.length,
          itemBuilder: (context, i) => HistoryRow(
            entry: list[i],
            onTap: () => onOpenDay(list[i].day),
          ),
        );
      },
    );
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, d MMM y').format(entry.day),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Newlines would otherwise make a one-line preview grow.
              entry.body.replaceAll(RegExp(r'\s+'), ' ').trim(),
              key: const ValueKey('preview'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
