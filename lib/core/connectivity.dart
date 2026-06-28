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
  ConnectivityEndpoint({
    this.v4,
    this.v6,
    this.dualStack = false,
    this.hasNat64Or6 = false,
  });
}

class ConnectivityEngine {
  static ConnectivityResult evaluate(
    ConnectivityEndpoint a,
    ConnectivityEndpoint b,
  ) {
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

    if (a.dualStack && b.dualStack) {
      return ConnectivityResult(
        ConnectivityKind.dualStackCommonFamily,
        'Posible por dual-stack declarado',
        [
          'Ambos extremos declaran pila dual. La conectividad debería usar una familia común disponible, idealmente IPv6, pero esta pantalla no verifica direcciones ni rutas adicionales de esa segunda pila.',
        ],
      );
    }
    if (a.hasNat64Or6 || b.hasNat64Or6) {
      return ConnectivityResult(
        ConnectivityKind.translatedNat64,
        'Posible mediante traducción/túnel declarado',
        [
          'Alguno de los extremos declara un mecanismo de traducción o túnel. La conectividad puede existir si ese mecanismo está correctamente desplegado y tiene rutas de ida y vuelta.',
          'Si el caso es NAT64 con Well-Known Prefix 64:ff9b::/96, verifica que la IPv4 involucrada sea global (RFC 6052 §3.1).',
        ],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.noPath,
      'Sin camino directo declarado',
      [
        'Las direcciones son de familias distintas (IPv4 vs IPv6) y ninguno de los extremos declara dual-stack ni un mecanismo de traducción/túnel disponible.',
        'Opciones: habilitar dual-stack o desplegar un mecanismo de traducción/túnel adecuado al escenario.',
      ],
    );
  }

  static ConnectivityResult _evaluateIpv4(Ipv4Prefix a, Ipv4Prefix b) {
    final sameLink = a.length == b.length && a.network == b.network;
    if (sameLink) {
      return ConnectivityResult(
        ConnectivityKind.sameLinkDirect,
        'Mismo enlace IPv4',
        [
          'Ambas direcciones pertenecen a la misma red ${a.toString()}: ARP puede resolver la dirección de capa 2 sin salto de router, asumiendo que comparten el mismo dominio de enlace.',
        ],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.routedSameFamily,
      'Requiere ruteo IPv4',
      [
        'Las direcciones están en redes distintas (${a.toString()} y ${b.toString()}); se requiere un router con ruta hacia cada prefijo y de vuelta. Esta pantalla no verifica la tabla de rutas real.',
      ],
    );
  }

  static ConnectivityResult _evaluateIpv6(Ipv6Prefix a, Ipv6Prefix b) {
    final sameLink = a.length == b.length && a.networkStart == b.networkStart;
    if (sameLink) {
      return ConnectivityResult(
        ConnectivityKind.sameLinkDirect,
        'Mismo enlace IPv6',
        [
          'Ambas direcciones comparten el prefijo de enlace ${a.toString()}: Neighbor Discovery (RFC 4861) puede resolver la dirección de capa 2 sin pasar por un router, asumiendo que comparten el mismo enlace.',
        ],
      );
    }
    return ConnectivityResult(
      ConnectivityKind.routedSameFamily,
      'Requiere ruteo IPv6',
      [
        'Las direcciones están en prefijos de enlace distintos (${a.toString()} y ${b.toString()}); se requiere un router con ruta hacia cada prefijo.',
      ],
    );
  }
}
