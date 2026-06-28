import 'package:test/test.dart';

import 'package:ipv4_ipv6_toolkit/core/ipv4.dart';
import 'package:ipv4_ipv6_toolkit/core/ipv6.dart';
import 'package:ipv4_ipv6_toolkit/core/subnetting.dart';

void main() {
  group('IPv4 subnetting', () {
    test('calcula la red base /24 sin transicion de mascara', () {
      final row = Ipv4SubnetRow(
        Ipv4Prefix(Ipv4Address.parse('192.168.0.1'), 24),
      );

      expect(row.network.dotted, '192.168.0.0');
      expect(row.hostMin?.dotted, '192.168.0.1');
      expect(row.hostMax?.dotted, '192.168.0.254');
      expect(row.broadcast.dotted, '192.168.0.255');
      expect(row.hostCount, 254);
    });

    test('divide una red /24 en dos subredes /25', () {
      final rows = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('192.168.0.1'),
        24,
        25,
      );

      expect(rows, hasLength(2));
      expect(rows[0].network.dotted, '192.168.0.0');
      expect(rows[0].hostMin?.dotted, '192.168.0.1');
      expect(rows[0].hostMax?.dotted, '192.168.0.126');
      expect(rows[0].broadcast.dotted, '192.168.0.127');
      expect(rows[0].hostCount, 126);
      expect(rows[1].network.dotted, '192.168.0.128');
      expect(rows[1].hostMin?.dotted, '192.168.0.129');
      expect(rows[1].hostMax?.dotted, '192.168.0.254');
      expect(rows[1].broadcast.dotted, '192.168.0.255');
      expect(rows.fold<int>(0, (sum, row) => sum + row.hostCount), 252);
    });

    test('mantiene una sola red cuando la mascara destino es igual', () {
      final rows = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('192.168.0.1'),
        24,
        24,
      );

      expect(rows, hasLength(1));
      expect(rows.single.network.dotted, '192.168.0.0');
      expect(rows.single.broadcast.dotted, '192.168.0.255');
      expect(rows.single.hostCount, 254);
    });

    test('divide una red /24 en cuatro subredes /26', () {
      final rows = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('192.168.0.1'),
        24,
        26,
      );

      expect(rows, hasLength(4));
      expect(rows[0].network.dotted, '192.168.0.0');
      expect(rows[0].hostMin?.dotted, '192.168.0.1');
      expect(rows[0].hostMax?.dotted, '192.168.0.62');
      expect(rows[0].broadcast.dotted, '192.168.0.63');
      expect(rows[0].hostCount, 62);
      expect(rows[3].network.dotted, '192.168.0.192');
      expect(rows[3].broadcast.dotted, '192.168.0.255');
      expect(rows.fold<int>(0, (sum, row) => sum + row.hostCount), 248);
    });

    test('divide una red /24 en ocho subredes /27', () {
      final rows = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('192.168.0.1'),
        24,
        27,
      );

      expect(rows, hasLength(8));
      expect(rows[0].network.dotted, '192.168.0.0');
      expect(rows[0].hostMin?.dotted, '192.168.0.1');
      expect(rows[0].hostMax?.dotted, '192.168.0.30');
      expect(rows[0].broadcast.dotted, '192.168.0.31');
      expect(rows[0].hostCount, 30);
      expect(rows[1].network.dotted, '192.168.0.32');
      expect(rows[1].hostMin?.dotted, '192.168.0.33');
      expect(rows[1].hostMax?.dotted, '192.168.0.62');
      expect(rows[1].broadcast.dotted, '192.168.0.63');
      expect(rows[7].network.dotted, '192.168.0.224');
      expect(rows[7].hostMin?.dotted, '192.168.0.225');
      expect(rows[7].hostMax?.dotted, '192.168.0.254');
      expect(rows[7].broadcast.dotted, '192.168.0.255');
      expect(rows.fold<int>(0, (sum, row) => sum + row.hostCount), 240);
    });

    test('agrega una /26 a su superred /24', () {
      final rows = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('192.168.0.65'),
        26,
        24,
      );

      expect(rows, hasLength(1));
      expect(rows.single.network.dotted, '192.168.0.0');
      expect(rows.single.broadcast.dotted, '192.168.0.255');
      expect(rows.single.hostCount, 254);
    });

    test(
      'agrega una /24 a una superred /16 cuando la nueva mascara es menor',
      () {
        final rows = Ipv4Subnetting.transitionMask(
          Ipv4Address.parse('192.168.0.65'),
          24,
          16,
        );

        expect(rows, hasLength(1));
        expect(rows.single.network.dotted, '192.168.0.0');
        expect(rows.single.broadcast.dotted, '192.168.255.255');
        expect(rows.single.hostCount, 65534);
      },
    );

    test('rechaza nueva mascara IPv4 fuera de rango', () {
      expect(
        () => Ipv4Subnetting.transitionMask(
          Ipv4Address.parse('192.168.0.1'),
          24,
          33,
        ),
        throwsA(isA<Ipv4SubnettingException>()),
      );

      expect(
        () => Ipv4Subnetting.transitionMask(
          Ipv4Address.parse('192.168.0.1'),
          24,
          -1,
        ),
        throwsA(isA<Ipv4SubnettingException>()),
      );
    });

    test('rechaza mascara original IPv4 fuera de rango', () {
      expect(
        () => Ipv4Subnetting.transitionMask(
          Ipv4Address.parse('192.168.0.1'),
          33,
          24,
        ),
        throwsA(isA<Ipv4FormatException>()),
      );

      expect(
        () => Ipv4Subnetting.transitionMask(
          Ipv4Address.parse('192.168.0.1'),
          -1,
          24,
        ),
        throwsA(isA<Ipv4FormatException>()),
      );
    });

    test('mantiene semantica correcta para /31 punto a punto', () {
      final row = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('198.51.100.10'),
        31,
        31,
      ).single;

      expect(row.network.dotted, '198.51.100.10');
      expect(row.hostMin?.dotted, '198.51.100.10');
      expect(row.hostMax?.dotted, '198.51.100.11');
      expect(row.hostCount, 2);
    });

    test('mantiene semantica correcta para /32 host route', () {
      final row = Ipv4Subnetting.transitionMask(
        Ipv4Address.parse('203.0.113.7'),
        32,
        32,
      ).single;

      expect(row.network.dotted, '203.0.113.7');
      expect(row.hostMin?.dotted, '203.0.113.7');
      expect(row.hostMax?.dotted, '203.0.113.7');
      expect(row.hostCount, 1);
    });

    test('redondea cantidad de subredes a la siguiente potencia de dos', () {
      final plan = Ipv4Subnetting.byDesiredSubnetCount(
        Ipv4Prefix(Ipv4Address.parse('192.168.0.1'), 24),
        3,
      );

      expect(plan.newLength, 26);
      expect(plan.deliveredCount, 4);
      expect(plan.wasRounded, isTrue);
      expect(plan.rows, hasLength(4));
    });

    test('calcula prefijo por hosts utilizables', () {
      final plan = Ipv4Subnetting.byHostsPerSubnet(
        Ipv4Prefix(Ipv4Address.parse('192.168.0.1'), 24),
        50,
      );

      expect(plan.newLength, 26);
      expect(plan.rows, hasLength(4));
      expect(plan.rows.first.hostCount, 62);
    });

    test('asigna VLSM de mayor a menor sin solapamientos', () {
      final rows = Ipv4Subnetting.vlsm(
        Ipv4Prefix(Ipv4Address.parse('10.0.0.0'), 24),
        [100, 50, 10],
      );

      expect(rows.map((p) => '${p.network.dotted}/${p.length}'), [
        '10.0.0.0/25',
        '10.0.0.128/26',
        '10.0.0.192/28',
      ]);
    });

    test('agrega prefijos contiguos del mismo tamano', () {
      final aggregated = Ipv4Subnetting.aggregate([
        Ipv4Prefix(Ipv4Address.parse('192.168.0.0'), 25),
        Ipv4Prefix(Ipv4Address.parse('192.168.0.128'), 25),
      ]);

      expect(aggregated, hasLength(1));
      expect(aggregated.single.network.dotted, '192.168.0.0');
      expect(aggregated.single.length, 24);
    });
  });

  group('IPv6 subnetting', () {
    test('divide un sitio /48 en subredes /56', () {
      final rows = Ipv6Subnetting.transitionMask(
        Ipv6Address.parse('2001:db8:1200::1'),
        48,
        56,
      );

      expect(rows, hasLength(256));
      expect(rows.first.networkStart.canonical, '2001:db8:1200::');
      expect(rows.first.length, 56);
      expect(rows[1].networkStart.canonical, '2001:db8:1200:100::');
      expect(rows.last.networkStart.canonical, '2001:db8:1200:ff00::');
    });

    test('agrega una /56 a su superred /48', () {
      final rows = Ipv6Subnetting.transitionMask(
        Ipv6Address.parse('2001:db8:1200:1200::1'),
        56,
        48,
      );

      expect(rows, hasLength(1));
      expect(rows.single.networkStart.canonical, '2001:db8:1200::');
      expect(rows.single.length, 48);
    });

    test('rechaza nueva mascara IPv6 fuera de rango', () {
      expect(
        () => Ipv6Subnetting.transitionMask(
          Ipv6Address.parse('2001:db8:1200::'),
          48,
          129,
        ),
        throwsA(isA<Ipv6SubnettingException>()),
      );

      expect(
        () => Ipv6Subnetting.transitionMask(
          Ipv6Address.parse('2001:db8:1200::'),
          48,
          -1,
        ),
        throwsA(isA<Ipv6SubnettingException>()),
      );
    });

    test('rechaza mascara original IPv6 fuera de rango', () {
      expect(
        () => Ipv6Subnetting.transitionMask(
          Ipv6Address.parse('2001:db8:1200::'),
          129,
          64,
        ),
        throwsA(isA<Ipv6FormatException>()),
      );

      expect(
        () => Ipv6Subnetting.transitionMask(
          Ipv6Address.parse('2001:db8:1200::'),
          -1,
          64,
        ),
        throwsA(isA<Ipv6FormatException>()),
      );
    });

    test('rechaza divisiones IPv6 demasiado grandes para mostrar', () {
      expect(
        () => Ipv6Subnetting.transitionMask(
          Ipv6Address.parse('2001:db8:1200::'),
          48,
          64,
        ),
        throwsA(isA<Ipv6FormatException>()),
      );
    });

    test('redondea cantidad de subredes IPv6 a potencia de dos', () {
      final plan = Ipv6Subnetting.byDesiredSubnetCount(
        Ipv6Prefix(Ipv6Address.parse('2001:db8:1200::'), 48),
        300,
      );

      expect(plan.newLength, 57);
      expect(plan.deliveredCount, 512);
      expect(plan.wasRounded, isTrue);
      expect(plan.rows, hasLength(512));
    });
  });
}
