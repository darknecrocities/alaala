import 'package:alaala/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Ala-ala home screen', (tester) async {
    await tester.pumpWidget(const AlaAlaApp());

    expect(find.text('Magandang umaga, Maria.'), findsOneWidget);
    expect(find.text('MemoryLens'), findsAtLeastNWidgets(1));
    expect(find.text('Sino ang kasama ko?'), findsOneWidget);
  });
}
