import 'ipv4.dart';
import 'ipv6.dart';

enum ConnectivityKind {
  sameLinkDirect,
  routedSameFamily,
  dualStackCommonFamily,
  translatedNat64,
  translatedSiit,
  translated6to4,
  noPath,
}

class ConnectivityResult {
  final ConnectivityKind kind;
  final String title;
  final List<String> details;
  ConnectivityResult(this.kind, this.title, this.details);
}

class ConnectivityEndpoint {
  final Ipv4Prefix? v4;
  final Ipv6Prefix? v6;
  final bool dualStack;
  final bool hasNat64Or6;
  ConnectivityEndpoint({this.v4, this.v6, this.dualStack = false, this.hasNat64Or6 = false});
}

/// Motor de decisión de conectividad: separa "misma familia + mismo enlace",
/// "misma familia + ruteo", "dual-stack" y "traducción/túnel" como casos
/// explícitos, en vez de asumir que coincidencia de prefijo basta.
class ConnectivityEngine {
  static ConnectivityResult evaluate(ConnectivityEndpoint a, ConnectivityEndpoint b) {
    final aHasV4 = a.v4 != null;
    final bHasV4 = b.v4 != null;
    final aHasV6 = a.v6 != null;
    final bHasV6 = b.v6 != null;

    if (aHasV4 && bHasV4) {
      return _evaluateIpv4(a.v4!, b.v4!);
    }
    if (aHasV6 && bHasV6) {
      return _evaluateIpv6(a.v6!, b.v6!);
    }

    // Familias distintas.
    if (a.dualStack && b.dualStack) {
      return ConnectivityResult(
        ConnectivityKind.dualStackCommonFamily,
        'Conectividad por dual-stack',
        [
          'Ambos extremos tienen pila dual; deben preferir la familia común disponible (idealmente IPv6) en lugar de traducir.',
        ],
      );
    }
    if (a.hasNat64Or6 || b.hasNat64Or6) {
      return ConnectivityResult(
        ConnectivityKind.translatedNat64,
        'Conectividad mediante traducción (NAT64/DNS64 o SIIT)',
        [
          'Un cliente IPv6-only puede alcanzar un servicio IPv4-only a través de NAT64 stateful (RFC 6146) con DNS64 (RFC 6147), o mediante traducción stateless SIIT (RFC 7915) si ambos extremos están bajo el mismo dominio de traducción.',
          'Verifica que la IPv4 involucrada sea global si se usa el Well-Known Prefix 64:ff9b::/96 (RFC 6052 §3.1).',
        ],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.noPath,
      'Sin conectividad directa entre familias',
      [
        'Las direcciones son de familias distintas (IPv4 vs IPv6) y ninguno de los extremos declara dual-stack ni un traductor disponible (NAT64/SIIT/DS-Lite/MAP).',
        'Opciones: habilitar dual-stack en alguno de los extremos, o desplegar NAT64+DNS64, SIIT, DS-Lite, MAP-E o MAP-T según el escenario.',
      ],
    );
  }

  static ConnectivityResult _evaluateIpv4(Ipv4Prefix a, Ipv4Prefix b) {
    final sameLink = a.length == b.length && a.network == b.network;
    if (sameLink) {
      return ConnectivityResult(
        ConnectivityKind.sameLinkDirect,
        'Conectividad directa (mismo enlace IPv4)',
        ['Ambas direcciones pertenecen a la misma red ${a.toString()}: ARP resuelve la dirección de capa 2 y no se requiere salto de router.'],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.routedSameFamily,
      'Conectividad por ruteo (IPv4)',
      [
        'Las direcciones están en redes distintas (${a.toString()} y ${b.toString()}); se requiere un router con ruta hacia cada prefijo y de vuelta (no se verifica aquí la tabla de rutas real, solo la pertenencia a subredes distintas).',
      ],
    );
  }

  static ConnectivityResult _evaluateIpv6(Ipv6Prefix a, Ipv6Prefix b) {
    final sameLink = a.length == b.length && a.networkStart == b.networkStart;
    if (sameLink) {
      return ConnectivityResult(
        ConnectivityKind.sameLinkDirect,
        'Conectividad directa (mismo enlace IPv6)',
        ['Ambas direcciones comparten el prefijo de enlace ${a.toString()}: Neighbor Discovery (RFC 4861) resuelve la dirección de capa 2 sin pasar por un router.'],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.routedSameFamily,
      'Conectividad por ruteo (IPv6)',
      [
        'Las direcciones están en prefijos de enlace distintos (${a.toString()} y ${b.toString()}); se requiere un router con ruta hacia cada prefijo.',
      ],
    );
  }
}
