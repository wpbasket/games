import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/main.dart';

void main() {
  testWidgets('LudoApp launches and displays game modes', (WidgetTester tester) async {
    await tester.pumpWidget(const LudoApp());
    await tester.pumpAndSettle();

    expect(find.text('ttcLudo'), findsOneWidget);
    expect(find.text('Custom Match Builder (All Combinations)'), findsOneWidget);
    expect(find.text('1 Player vs 3 Bots'), findsOneWidget);
    expect(find.text('1 Player vs 1 Bot (Duel)'), findsOneWidget);
    expect(find.text('2 Players vs 2 Bots'), findsOneWidget);
    expect(find.text('4 Players (Pass & Play)'), findsOneWidget);
  });
}
