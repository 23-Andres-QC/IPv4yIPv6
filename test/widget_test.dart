import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipv4_ipv6_toolkit/main.dart';

void main() {
  testWidgets('La app arranca y muestra la calculadora por defecto', (WidgetTester tester) async {
    await tester.pumpWidget(const IpToolkitApp());
    expect(find.text('Calculadora de direcciones'), findsOneWidget);
    expect(find.byIcon(Icons.hub), findsOneWidget);
  });
}
