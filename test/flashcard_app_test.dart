import 'package:flash_card/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlashcardApp builds without crashing', (tester) async {
    await tester.pumpWidget(const FlashcardApp());

    expect(find.byType(FlashcardApp), findsOneWidget);
  });
}
