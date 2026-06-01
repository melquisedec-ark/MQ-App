import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himnario_id_2/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HimnarioApp(),
      ),
    );

    // Verify the app renders
    expect(find.text('HimnarioID'), findsWidgets);
  });
}
