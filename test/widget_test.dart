import 'package:flutter_test/flutter_test.dart';
import 'package:thirdspace/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ThirdSpaceApp());
    expect(find.text('ThirdSpace'), findsOneWidget);
  });
}
