import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';

/// One journal page. The writing area is the hero; everything else recedes.
///
/// There is no Save button by design — typing stops, the entry saves. See
/// PLAN.md step 1.2.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, required this.day});

  final DateTime day;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry =
        await ref.read(entryRepositoryProvider).entryFor(widget.day);
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
    await ref.read(entryRepositoryProvider).saveBody(widget.day, body);
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  void dispose() {
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
                  _DateHeader(day: widget.day, saved: _saved),
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
  const _DateHeader({required this.day, required this.saved});

  final DateTime day;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
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
      ],
    );
  }
}
