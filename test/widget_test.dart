import 'package:daybook/main.dart';
import 'package:daybook/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('the app boots and shows today', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: inMemoryOverrides(), child: const DaybookApp()),
    );

    final today = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    expect(find.text(today), findsOneWidget);
  });
}
