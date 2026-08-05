import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories.dart';
import '../../providers.dart';

/// One journal page. The writing area is the hero; everything else recedes.
///
/// There is no Save button by design — typing stops, the entry saves. See
/// PLAN.md step 1.2.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({
    super.key,
    required this.day,
    this.onNavigate,
    this.onOpenHistory,
  });

  final DateTime day;

  /// Supplied by [JournalScreen]. When null the page has no day controls,
  /// which is how it is exercised in isolation.
  final ValueChanged<DateTime>? onNavigate;

  /// Only supplied when the window is too narrow for a history column, so the
  /// control does not appear next to a list that is already on screen.
  final VoidCallback? onOpenHistory;

  /// Quiet enough not to thrash the disk mid-sentence, short enough that
  /// closing the window straight after typing does not lose the last words.
  static const autosaveDebounce = Duration(milliseconds: 800);

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _saved = false;

  /// Captured up front so a pending save can still be flushed from [dispose],
  /// where reading a provider is no longer allowed.
  late final EntryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(entryRepositoryProvider);
    _load();
  }

  Future<void> _load() async {
    final entry = await _repository.entryFor(widget.day);
    if (!mounted) return;
    _controller.text = entry?.body ?? '';
    setState(() => _loading = false);
  }

  void _onChanged(String value) {
    if (_saved) setState(() => _saved = false);
    _debounce?.cancel();
    _debounce = Timer(EntryScreen.autosaveDebounce, () => _save(value));
  }

  Future<void> _save(String body) async {
    await _repository.saveBody(widget.day, body);
    if (!mounted) return;
    ref.invalidate(recentEntriesProvider);
    setState(() => _saved = true);
  }

  @override
  void dispose() {
    // Leaving the page mid-debounce must not cost the user their last
    // sentence. Fire-and-forget against the day this page was showing — by the
    // time this runs, the day on screen may already be a different one.
    if (_debounce?.isActive ?? false) {
      _repository.saveBody(widget.day, _controller.text);
    }
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // A comfortable measure — long lines are tiring to read.
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateHeader(
                    day: widget.day,
                    saved: _saved,
                    onNavigate: widget.onNavigate,
                    onOpenHistory: widget.onOpenHistory,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _loading
                        ? const SizedBox.shrink()
                        : TextField(
                            controller: _controller,
                            onChanged: _onChanged,
                            autofocus: true,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            cursorColor: theme.colorScheme.primary,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write about today…',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.day,
    required this.saved,
    this.onNavigate,
    this.onOpenHistory,
  });

  final DateTime day;
  final bool saved;
  final ValueChanged<DateTime>? onNavigate;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigate = onNavigate;

    return Row(
      children: [
        if (navigate != null) ...[
          _NavButton(
            tooltip: 'Previous day',
            icon: Icons.chevron_left,
            onPressed: () =>
                navigate(DateTime(day.year, day.month, day.day - 1)),
          ),
          _NavButton(
            tooltip: 'Next day',
            icon: Icons.chevron_right,
            onPressed: () =>
                navigate(DateTime(day.year, day.month, day.day + 1)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            DateFormat('EEEE, d MMMM y').format(day),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Switched rather than faded to opacity zero: an invisible-but-present
        // "Saved" would still be announced by a screen reader before anything
        // had been saved.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: saved
              ? Text(
                  'Saved',
                  key: const ValueKey('saved-indicator'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (onOpenHistory case final open?)
          _NavButton(
            tooltip: 'History',
            icon: Icons.history,
            onPressed: open,
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      onPressed: onPressed,
    );
  }
}
