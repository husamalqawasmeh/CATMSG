import 'package:catmsg/main.dart';
import 'package:catmsg/services/cat_backend_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CatMsg renders Discord layout, channels, and quests', (
    WidgetTester tester,
  ) async {
    final backend = CatBackendService(firebaseReady: false);
    await tester.pumpWidget(CatMsgApp(backend: backend));

    // Verify default server and channel load
    expect(find.text('The Grand Cat Castle'), findsWidgets);
    expect(find.text('general-meows'), findsWidgets);

    // Verify MeowCoins counter renders
    expect(find.textContaining('120'), findsWidgets);
  });
}
