import 'package:flutter_test/flutter_test.dart';

import 'package:hellochat/main.dart';

void main() {
  testWidgets('HomeScreen affiche le logo et le bouton de démarrage', (WidgetTester tester) async {
    await tester.pumpWidget(const HelloChatApp());

    expect(find.text('HelloChat'), findsOneWidget);
    expect(find.text('Démarrer le Live'), findsOneWidget);
  });
}
