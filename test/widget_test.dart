import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipv4_ipv6_toolkit/main.dart';

void main() {
  testWidgets('La app arranca y muestra la calculadora por defecto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IpToolkitApp());
    expect(find.text('Calculadora de direcciones'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('La app cambia entre español e inglés', (tester) async {
    await tester.pumpWidget(const IpToolkitApp());

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Address calculator'), findsOneWidget);
    expect(
      find.text(
        'Enter an IP address and prefix to analyze the complete subnet.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('ES'));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora de direcciones'), findsOneWidget);
  });

  testWidgets('La app cambia entre tema claro y oscuro', (tester) async {
    await tester.pumpWidget(const IpToolkitApp());

    expect(
      Theme.of(
        tester.element(find.text('Calculadora de direcciones')),
      ).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(find.text('Calculadora de direcciones')),
      ).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(find.text('Calculadora de direcciones')),
      ).brightness,
      Brightness.light,
    );
  });
}
