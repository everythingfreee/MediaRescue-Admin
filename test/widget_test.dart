import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarescueadmin/main.dart';

void main() {
  testWidgets('MediaRescueAdminApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediaRescueAdminApp(),
      ),
    );
  });
}
