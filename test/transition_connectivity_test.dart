import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_ipv6_toolkit/core/connectivity.dart';
import 'package:ipv4_ipv6_toolkit/core/ipv4.dart';
import 'package:ipv4_ipv6_toolkit/core/ipv6.dart';
import 'package:ipv4_ipv6_toolkit/core/transition.dart';
import 'package:ipv4_ipv6_toolkit/screens/connectivity_screen.dart';
import 'package:ipv4_ipv6_toolkit/screens/ipv4_to_ipv6_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  test('RFC 6052 no muestra forma mixta duplicada si no aplica', () {
    final result = TransitionEngine.embedRfc6052(
      Ipv4Address.parse('192.0.2.33'),
      Ipv6Address.parse('64:ff9b:1::'),
      48,
    );

    expect(result.resultText.contains('(mixta:'), isFalse);
  });

  test('RFC 6052 /96 incrusta IPv4 sin error de desplazamiento', () {
    final result = TransitionEngine.embedRfc6052(
      Ipv4Address.parse('192.0.2.33'),
      Ipv6Address.parse('64:ff9b::'),
      96,
    );

    expect(result.resultText, contains('64:ff9b::c000:221'));
    expect(result.resultText, contains('64:ff9b::192.0.2.33'));
  });

  test('Conectividad habla como requisito de ruteo, no certeza absoluta', () {
    final result = ConnectivityEngine.evaluate(
      ConnectivityEndpoint(
        v4: Ipv4Prefix(Ipv4Address.parse('192.168.0.10'), 24),
      ),
      ConnectivityEndpoint(
        v4: Ipv4Prefix(Ipv4Address.parse('203.0.113.5'), 28),
      ),
    );

    expect(result.title, 'Requiere ruteo IPv4');
  });

  testWidgets('Transición IPv4 muestra los tres resultados juntos', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
    await tester.pump();

    expect(find.text('IPv4-mapped:'), findsOneWidget);
    expect(find.text('NAT64 (RFC 6052):'), findsOneWidget);
    expect(find.text('6to4:'), findsOneWidget);
    expect(find.text('64:ff9b::808:808'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Transición limpia resultado viejo al editar', (tester) async {
    await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
    await tester.pump();

    expect(find.textContaining('64:ff9b::808:808'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '198.51.100.7');
    await tester.pump();

    expect(find.textContaining('64:ff9b::808:808'), findsNothing);
  });

  testWidgets('Transición IPv4 incorrecta no muestra resultados', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));

    await tester.enterText(find.byType(TextField).first, '999.1.1.1');
    await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
    await tester.pump();

    expect(find.text('Dirección IPv4 no válida'), findsOneWidget);
    expect(find.text('IPv4-mapped:'), findsNothing);
    expect(find.text('NAT64 (RFC 6052):'), findsNothing);
    expect(find.text('6to4:'), findsNothing);
  });

  testWidgets('Transición IPv6 detecta formato y muestra una sola IPv4', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));

    await tester.tap(find.text('IPv6 → IPv4'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
    await tester.pump();

    expect(find.text('IPv4:'), findsOneWidget);
    expect(find.text('8.8.8.8'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'Transición IPv6 válida sin formato reconocido indica que no contiene IPv4',
    (tester) async {
      await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));

      await tester.tap(find.text('IPv6 → IPv4'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '2001:db8::1');
      await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
      await tester.pump();

      expect(find.text('La dirección IPv6 no contiene IPv4.'), findsOneWidget);
      expect(find.text('IPv4:'), findsNothing);
    },
  );

  testWidgets('Transición IPv6 incorrecta muestra mensaje exacto', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Ipv4ToIpv6Screen()));

    await tester.tap(find.text('IPv6 → IPv4'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '2001:::bad');
    await tester.tap(find.widgetWithText(FilledButton, 'Transformar'));
    await tester.pump();

    expect(find.text('Dirección IPv6 no válida'), findsOneWidget);
    expect(find.text('IPv4:'), findsNothing);
  });

  testWidgets('Conectividad muestra advertencias para direcciones especiales', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ConnectivityScreen()));

    expect(find.text('Requiere ruteo IPv4'), findsOneWidget);
    expect(find.text('Advertencias'), findsOneWidget);
    expect(find.textContaining('IPv4 privada'), findsOneWidget);
    expect(find.textContaining('IPv4 de documentación'), findsOneWidget);
  });

  testWidgets('Conectividad limpia resultado viejo al editar', (tester) async {
    await tester.pumpWidget(wrap(const ConnectivityScreen()));

    expect(find.text('Requiere ruteo IPv4'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '10.0.0.1');
    await tester.pump();

    expect(find.text('Requiere ruteo IPv4'), findsNothing);
  });
}
