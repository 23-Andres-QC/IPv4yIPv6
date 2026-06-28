import 'package:test/test.dart';

import 'package:ipv4_ipv6_toolkit/core/ipv4.dart';
import 'package:ipv4_ipv6_toolkit/core/ipv6.dart';

void main() {
  group('IPv4 parsing and classification', () {
    test('clasifica direcciones privadas RFC 1918', () {
      expect(Ipv4Address.parse('10.0.0.1').classification, Ipv4Class.private);
      expect(Ipv4Address.parse('172.16.0.1').classification, Ipv4Class.private);
      expect(
        Ipv4Address.parse('172.31.255.254').classification,
        Ipv4Class.private,
      );
      expect(
        Ipv4Address.parse('192.168.0.1').classification,
        Ipv4Class.private,
      );
    });

    test('clasifica direcciones IPv4 especiales', () {
      expect(
        Ipv4Address.parse('0.0.0.0').classification,
        Ipv4Class.unspecified,
      );
      expect(Ipv4Address.parse('127.0.0.1').classification, Ipv4Class.loopback);
      expect(
        Ipv4Address.parse('169.254.1.1').classification,
        Ipv4Class.linkLocal,
      );
      expect(
        Ipv4Address.parse('100.64.0.1').classification,
        Ipv4Class.sharedCgnat,
      );
      expect(
        Ipv4Address.parse('192.0.2.33').classification,
        Ipv4Class.documentation,
      );
      expect(
        Ipv4Address.parse('198.51.100.33').classification,
        Ipv4Class.documentation,
      );
      expect(
        Ipv4Address.parse('203.0.113.33').classification,
        Ipv4Class.documentation,
      );
      expect(
        Ipv4Address.parse('198.18.0.1').classification,
        Ipv4Class.benchmarking,
      );
      expect(
        Ipv4Address.parse('224.0.0.1').classification,
        Ipv4Class.multicast,
      );
      expect(Ipv4Address.parse('240.0.0.1').classification, Ipv4Class.reserved);
      expect(
        Ipv4Address.parse('255.255.255.255').classification,
        Ipv4Class.broadcastLimited,
      );
    });

    test('clasifica direcciones IPv4 globales publicas', () {
      expect(Ipv4Address.parse('8.8.8.8').classification, Ipv4Class.global);
      expect(Ipv4Address.parse('1.1.1.1').classification, Ipv4Class.global);
      expect(Ipv4Address.parse('172.32.0.1').classification, Ipv4Class.global);
    });

    test('rechaza direcciones IPv4 invalidas', () {
      for (final input in [
        '',
        '192.168.1',
        '192.168.1.1.1',
        '192.168.1.-1',
        '192.168.1.256',
        '192.168.one.1',
      ]) {
        expect(
          () => Ipv4Address.parse(input),
          throwsA(isA<Ipv4FormatException>()),
        );
      }
    });
  });

  group('IPv6 parsing and classification', () {
    test('clasifica direcciones IPv6 especiales', () {
      expect(Ipv6Address.parse('::').classification, Ipv6Class.unspecified);
      expect(Ipv6Address.parse('::1').classification, Ipv6Class.loopback);
      expect(Ipv6Address.parse('fe80::1').classification, Ipv6Class.linkLocal);
      expect(
        Ipv6Address.parse('fc00::1').classification,
        Ipv6Class.uniqueLocal,
      );
      expect(
        Ipv6Address.parse('fd12:3456:789a::1').classification,
        Ipv6Class.uniqueLocal,
      );
      expect(Ipv6Address.parse('ff02::1').classification, Ipv6Class.multicast);
      expect(
        Ipv6Address.parse('2001:db8::1').classification,
        Ipv6Class.documentation,
      );
      expect(
        Ipv6Address.parse('2002:c000:0201::').classification,
        Ipv6Class.sixToFour,
      );
      expect(Ipv6Address.parse('2001::1').classification, Ipv6Class.teredo);
      expect(
        Ipv6Address.parse('2001:4860:4860::8888').classification,
        Ipv6Class.globalUnicast,
      );
    });

    test('clasifica mecanismos IPv4 embebidos en IPv6', () {
      expect(
        Ipv6Address.parse('::ffff:192.0.2.33').classification,
        Ipv6Class.ipv4Mapped,
      );
      expect(
        Ipv6Address.parse('64:ff9b::192.0.2.33').classification,
        Ipv6Class.nat64WellKnown,
      );
      expect(
        Ipv6Address.parse('64:ff9b:1::192.0.2.33').classification,
        Ipv6Class.nat64Local,
      );
    });

    test('normaliza formas IPv6 validas', () {
      expect(
        Ipv6Address.parse('2001:0db8:0000:0000:0000:0000:0000:0001').canonical,
        '2001:db8::1',
      );
      expect(
        Ipv6Address.parse('::ffff:c000:221').mixedFormIfApplicable,
        '::ffff:192.0.2.33',
      );
    });

    test('rechaza direcciones IPv6 invalidas', () {
      for (final input in [
        '',
        '2001::db8::1',
        '2001:db8:0:0:0:0:0:0:1',
        '2001:db8::gggg',
        '12345::1',
      ]) {
        expect(
          () => Ipv6Address.parse(input),
          throwsA(isA<Ipv6FormatException>()),
        );
      }
    });
  });
}
