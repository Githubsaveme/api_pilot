import 'package:flutter_test/flutter_test.dart';
import 'package:easy_api_kit_example/main.dart';

void main() {
  testWidgets('EasyApiExampleApp renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyApiExampleApp());
    expect(find.text('EasyApiKit Showcase'), findsOneWidget);
  });
}
