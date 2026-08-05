/// Builds the one-line preview shown in a history row.
///
/// When the row is a search result, the window is centred on the match — a
/// preview that always started at the beginning of the entry would rarely show
/// you why the row matched.
String previewAround(String body, String query, {int radius = 40}) {
  // Newlines and runs of spaces would otherwise make a "one line" preview
  // render as blank or ragged.
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (query.isEmpty) return flat;

  final at = flat.toLowerCase().indexOf(query.toLowerCase());
  if (at < 0) return flat;

  final start = (at - radius).clamp(0, flat.length);
  final end = (at + query.length + radius).clamp(0, flat.length);

  final leading = start > 0 ? '…' : '';
  final trailing = end < flat.length ? '…' : '';

  return '$leading${flat.substring(start, end)}$trailing';
}
