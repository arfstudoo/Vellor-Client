import 'package:flutter_test/flutter_test.dart';
import 'package:vellor_client/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const VellorApp());
  });
}
