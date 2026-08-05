import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'entry_preview.dart';

/// Past days, newest first — filtered to matches while a search is active.
class HistoryPane extends ConsumerWidget {
  const HistoryPane({super.key, required this.onOpenDay});

  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(visibleEntriesProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final theme = Theme.of(context);

    Widget message(String text) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        );

    return Column(
      children: [
        const _SearchField(),
        Expanded(
          child: entries.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => message('Could not load entries'),
            data: (list) {
              if (list.isEmpty) {
                return message(
                  query.isEmpty ? 'No entries yet' : 'No matching entries',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: list.length,
                itemBuilder: (context, i) => HistoryRow(
                  entry: list[i],
                  query: query,
                  onTap: () => onOpenDay(list[i].day),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 34),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.query = '',
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final String query;

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
              previewAround(entry.body, query),
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
