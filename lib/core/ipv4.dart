/// Direcciones IPv4 (RFC 791) con soporte CIDR (RFC 4632).
class Ipv4FormatException implements Exception {
  final String message;
  Ipv4FormatException(this.message);
  @override
  String toString() => message;
}

class Ipv4Address implements Comparable<Ipv4Address> {
  /// Valor de 32 bits sin signo almacenado en un int de Dart (seguro: cabe en 53 bits).
  final int value;

  const Ipv4Address(this.value);

  static Ipv4Address? tryParse(String text) {
    try {
      return Ipv4Address.parse(text);
    } catch (_) {
      return null;
    }
  }

  factory Ipv4Address.parse(String text) {
    final parts = text.trim().split('.');
    if (parts.length != 4) {
      throw Ipv4FormatException('"$text" no tiene 4 octetos separados por puntos.');
    }
    var v = 0;
    for (final p in parts) {
      if (p.isEmpty || !RegExp(r'^\d+$').hasMatch(p)) {
        throw Ipv4FormatException('Octeto inválido: "$p".');
      }
      final n = int.parse(p);
      if (n < 0 || n > 255) {
        throw Ipv4FormatException('Octeto fuera de rango (0-255): $n.');
      }
      v = (v << 8) | n;
    }
    return Ipv4Address(v);
  }

  factory Ipv4Address.fromInt(int v) => Ipv4Address(v & 0xFFFFFFFF);

  List<int> get octets => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  String get dotted => octets.join('.');

  String get hex => '0x${value.toRadixString(16).padLeft(8, '0')}';

  String get binary =>
      octets.map((o) => o.toRadixString(2).padLeft(8, '0')).join('.');

  Ipv4Address operator &(Ipv4Address other) =>
      Ipv4Address.fromInt(value & other.value);
  Ipv4Address operator |(Ipv4Address other) =>
      Ipv4Address.fromInt(value | other.value);
  Ipv4Address get complement => Ipv4Address.fromInt(~value);

  Ipv4Address operator +(int delta) => Ipv4Address.fromInt(value + delta);
  Ipv4Address operator -(int delta) => Ipv4Address.fromInt(value - delta);

  @override
  int compareTo(Ipv4Address other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) => other is Ipv4Address && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => dotted;

  /// Clasificación de la dirección según RFC 1918, RFC 5737, RFC 3927, etc.
  Ipv4Class get classification {
    if (value == 0) return Ipv4Class.unspecified;
    if (value == 0xFFFFFFFF) return Ipv4Class.broadcastLimited;
    if (_inRange('127.0.0.0', 8)) return Ipv4Class.loopback;
    if (_inRange('10.0.0.0', 8)) return Ipv4Class.private;
    if (_inRange('172.16.0.0', 12)) return Ipv4Class.private;
    if (_inRange('192.168.0.0', 16)) return Ipv4Class.private;
    if (_inRange('169.254.0.0', 16)) return Ipv4Class.linkLocal;
    if (_inRange('100.64.0.0', 10)) return Ipv4Class.sharedCgnat;
    if (_inRange('192.0.2.0', 24)) return Ipv4Class.documentation;
    if (_inRange('198.51.100.0', 24)) return Ipv4Class.documentation;
    if (_inRange('203.0.113.0', 24)) return Ipv4Class.documentation;
    if (_inRange('198.18.0.0', 15)) return Ipv4Class.benchmarking;
    if (_inRange('224.0.0.0', 4)) return Ipv4Class.multicast;
    if (_inRange('240.0.0.0', 4)) return Ipv4Class.reserved;
    return Ipv4Class.global;
  }

  bool _inRange(String base, int prefix) {
    final net = Ipv4Address.parse(base);
    final mask = Ipv4Prefix.maskForLength(prefix);
    return (this & mask) == (net & mask);
  }
}

enum Ipv4Class {
  unspecified,
  loopback,
  private,
  linkLocal,
  sharedCgnat,
  documentation,
  benchmarking,
  multicast,
  broadcastLimited,
  reserved,
  global,
}

extension Ipv4ClassLabel on Ipv4Class {
  String get label {
    switch (this) {
      case Ipv4Class.unspecified:
        return 'No especificada (0.0.0.0)';
      case Ipv4Class.loopback:
        return 'Loopback (127.0.0.0/8)';
      case Ipv4Class.private:
        return 'Privada (RFC 1918)';
      case Ipv4Class.linkLocal:
        return 'Link-local / APIPA (169.254.0.0/16, RFC 3927)';
      case Ipv4Class.sharedCgnat:
        return 'Compartida CGN (100.64.0.0/10, RFC 6598)';
      case Ipv4Class.documentation:
        return 'Documentación (RFC 5737) — no usar en producción';
      case Ipv4Class.benchmarking:
        return 'Benchmarking (198.18.0.0/15, RFC 2544)';
      case Ipv4Class.multicast:
        return 'Multicast (clase D, 224.0.0.0/4)';
      case Ipv4Class.broadcastLimited:
        return 'Broadcast limitado (255.255.255.255)';
      case Ipv4Class.reserved:
        return 'Reservada (clase E, 240.0.0.0/4)';
      case Ipv4Class.global:
        return 'Unicast global (potencialmente ruteable en Internet)';
    }
  }
}

/// Prefijo / subred IPv4 en notación CIDR (RFC 4632), con caso especial
/// /31 para enlaces punto a punto (RFC 3021) y /32 como host route.
class Ipv4Prefix {
  final Ipv4Address address;
  final int length;

  Ipv4Prefix(this.address, this.length) {
    if (length < 0 || length > 32) {
      throw Ipv4FormatException('La longitud de prefijo IPv4 debe estar entre 0 y 32.');
    }
  }

  static Ipv4Prefix parse(String cidr) {
    final parts = cidr.trim().split('/');
    if (parts.length != 2) {
      throw Ipv4FormatException('Formato esperado: a.b.c.d/p');
    }
    final addr = Ipv4Address.parse(parts[0]);
    final len = int.tryParse(parts[1]);
    if (len == null) throw Ipv4FormatException('Prefijo inválido: "${parts[1]}".');
    return Ipv4Prefix(addr, len);
  }

  static Ipv4Address maskForLength(int p) {
    if (p == 0) return const Ipv4Address(0);
    return Ipv4Address.fromInt(0xFFFFFFFF << (32 - p));
  }

  Ipv4Address get mask => maskForLength(length);
  Ipv4Address get wildcard => mask.complement;
  Ipv4Address get network => address & mask;
  Ipv4Address get broadcastAddress => network | wildcard;

  BigInt get totalAddresses => BigInt.two.pow(32 - length);

  /// Reglas RFC 3021 (/31) y caso /32 (host route).
  int get usableHostCount {
    if (length <= 30) {
      final total = 1 << (32 - length);
      return total - 2;
    } else if (length == 31) {
      return 2;
    } else {
      return 1;
    }
  }

  Ipv4Address? get firstUsable {
    if (length <= 30) return network + 1;
    if (length == 31) return network;
    return network; // /32
  }

  Ipv4Address? get lastUsable {
    if (length <= 30) return broadcastAddress - 1;
    if (length == 31) return broadcastAddress;
    return network; // /32
  }

  bool contains(Ipv4Address ip) => (ip & mask) == network;

  /// Divide esta red en [count] subredes de igual tamaño (debe ser potencia de 2).
  List<Ipv4Prefix> splitInto(int count) {
    final bits = _log2Exact(count);
    final newLength = length + bits;
    if (newLength > 32) {
      throw Ipv4FormatException('No hay suficiente espacio para crear $count subredes.');
    }
    final blockSize = 1 << (32 - newLength);
    return List.generate(
      count,
      (i) => Ipv4Prefix(network + i * blockSize, newLength),
    );
  }

  /// Divide a un nuevo prefijo (más largo) explícito.
  List<Ipv4Prefix> splitToLength(int newLength) {
    if (newLength < length || newLength > 32) {
      throw Ipv4FormatException('Nueva longitud inválida.');
    }
    return splitInto(1 << (newLength - length));
  }

  static int _log2Exact(int n) {
    if (n <= 0 || (n & (n - 1)) != 0) {
      throw Ipv4FormatException('La cantidad de subredes debe ser una potencia de 2.');
    }
    var bits = 0;
    var v = n;
    while (v > 1) {
      v >>= 1;
      bits++;
    }
    return bits;
  }

  @override
  String toString() => '${address.dotted}/$length';
}
