import 'package:flutter_test/flutter_test.dart';
import 'package:magic_show_presenter/main.dart';

void main() {
  testWidgets('app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MagicShowApp());
    // Settings screen loads preferences async; pump once to trigger initState.
    await tester.pump();
    // A CircularProgressIndicator is shown while SharedPreferences loads.
    expect(find.byType(MagicShowApp), findsOneWidget);
  });
}
