import 'ipv4.dart';

/// Direcciones IPv6 de 128 bits (RFC 4291) con texto canónico (RFC 5952).
class Ipv6FormatException implements Exception {
  final String message;
  Ipv6FormatException(this.message);
  @override
  String toString() => message;
}

class Ipv6Address implements Comparable<Ipv6Address> {
  static final BigInt _mask128 = (BigInt.one << 128) - BigInt.one;

  /// Valor de 128 bits sin signo.
  final BigInt value;

  Ipv6Address(BigInt v) : value = v & _mask128;

  static Ipv6Address? tryParse(String text) {
    try {
      return Ipv6Address.parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Parser tolerante a "::", forma completa y forma mixta con IPv4 embebida
  /// (RFC 4291 §2.2).
  factory Ipv6Address.parse(String text) {
    var input = text.trim().toLowerCase();
    if (input.isEmpty) {
      throw Ipv6FormatException('Dirección vacía.');
    }
    // Quitar scope id tipo %eth0 si viene de una dirección link-local real.
    final pct = input.indexOf('%');
    if (pct != -1) input = input.substring(0, pct);

    final doubleColonCount = RegExp('::').allMatches(input).length;
    if (doubleColonCount > 1) {
      throw Ipv6FormatException('Solo se permite un "::" por dirección.');
    }

    List<String> expandGroup(List<String> groups) {
      if (groups.isEmpty) return groups;
      if (groups.last.contains('.')) {
        final ipv4 = Ipv4Address.parse(groups.last);
        final hi = (ipv4.value >> 16) & 0xFFFF;
        final lo = ipv4.value & 0xFFFF;
        return [
          ...groups.sublist(0, groups.length - 1),
          hi.toRadixString(16),
          lo.toRadixString(16),
        ];
      }
      return groups;
    }

    List<String> groups;
    if (doubleColonCount == 1) {
      final sides = input.split('::');
      final leftRaw = sides[0];
      final rightRaw = sides.length > 1 ? sides[1] : '';
      final left = leftRaw.isEmpty ? <String>[] : expandGroup(leftRaw.split(':'));
      final right = rightRaw.isEmpty ? <String>[] : expandGroup(rightRaw.split(':'));
      final missing = 8 - (left.length + right.length);
      if (missing < 0) {
        throw Ipv6FormatException('Demasiados grupos para una dirección IPv6.');
      }
      groups = [...left, ...List.filled(missing, '0'), ...right];
    } else {
      final raw = expandGroup(input.split(':'));
      groups = raw;
      if (groups.length != 8) {
        throw Ipv6FormatException(
            '"$text" debe tener 8 grupos de 16 bits (o usar "::").');
      }
    }

    if (groups.length != 8) {
      throw Ipv6FormatException('"$text" no es una dirección IPv6 válida.');
    }

    var acc = BigInt.zero;
    for (final g in groups) {
      if (g.isEmpty || g.length > 4 || !RegExp(r'^[0-9a-f]{1,4}$').hasMatch(g)) {
        throw Ipv6FormatException('Grupo hexadecimal inválido: "$g".');
      }
      acc = (acc << 16) | BigInt.parse(g, radix: 16);
    }
    return Ipv6Address(acc);
  }

  factory Ipv6Address.fromIpv4Mapped(Ipv4Address ipv4) {
    final base = BigInt.parse('ffff00000000', radix: 16);
    return Ipv6Address(base | BigInt.from(ipv4.value));
  }

  List<int> get groups {
    final out = <int>[];
    for (var i = 7; i >= 0; i--) {
      out.add(((value >> (i * 16)) & BigInt.from(0xFFFF)).toInt());
    }
    return out;
  }

  String get fullForm =>
      groups.map((g) => g.toRadixString(16).padLeft(4, '0')).join(':');

  /// Representación canónica según RFC 5952: minúsculas, sin ceros a la
  /// izquierda, "::" para la corrida más larga de grupos en cero (longitud
  /// mínima 2, la más larga; en empate, la primera).
  String get canonical {
    final g = groups;
    int bestStart = -1, bestLen = 0;
    int curStart = -1, curLen = 0;
    for (var i = 0; i < 8; i++) {
      if (g[i] == 0) {
        if (curStart == -1) curStart = i;
        curLen++;
        if (curLen > bestLen) {
          bestLen = curLen;
          bestStart = curStart;
        }
      } else {
        curStart = -1;
        curLen = 0;
      }
    }
    if (bestLen < 2) {
      return g.map((x) => x.toRadixString(16)).join(':');
    }
    final left = g.sublist(0, bestStart).map((x) => x.toRadixString(16)).join(':');
    final right =
        g.sublist(bestStart + bestLen).map((x) => x.toRadixString(16)).join(':');
    if (bestStart == 0 && bestStart + bestLen == 8) return '::';
    if (bestStart == 0) return '::$right';
    if (bestStart + bestLen == 8) return '$left::';
    return '$left::$right';
  }

  /// Forma mixta recomendada por RFC 5952 cuando los últimos 32 bits son una
  /// IPv4 embebida bajo un prefijo /96 (IPv4-mapped o WKP NAT64).
  String get mixedFormIfApplicable {
    final cls = classification;
    if (cls != Ipv6Class.ipv4Mapped && cls != Ipv6Class.nat64WellKnown) {
      return canonical;
    }
    final ipv4 = Ipv4Address.fromInt((value & BigInt.from(0xFFFFFFFF)).toInt());
    final headText = _compressGroups(groups.sublist(0, 6));
    final sep = headText.endsWith('::') ? '' : ':';
    return '$headText$sep${ipv4.dotted}';
  }

  /// Compresión RFC 5952 de una lista parcial de grupos de 16 bits (sin el
  /// requisito de completar 8 grupos), usada para construir formas mixtas.
  static String _compressGroups(List<int> g) {
    int bestStart = -1, bestLen = 0, curStart = -1, curLen = 0;
    for (var i = 0; i < g.length; i++) {
      if (g[i] == 0) {
        if (curStart == -1) curStart = i;
        curLen++;
        if (curLen > bestLen) {
          bestLen = curLen;
          bestStart = curStart;
        }
      } else {
        curStart = -1;
        curLen = 0;
      }
    }
    if (bestLen < 2) {
      return g.map((x) => x.toRadixString(16)).join(':');
    }
    final left = g.sublist(0, bestStart).map((x) => x.toRadixString(16)).join(':');
    final right =
        g.sublist(bestStart + bestLen).map((x) => x.toRadixString(16)).join(':');
    if (bestStart == 0 && bestStart + bestLen == g.length) return '::';
    if (bestStart == 0) return '::$right';
    if (bestStart + bestLen == g.length) return '$left::';
    return '$left::$right';
  }

  String get binary => groups
      .map((g) => g.toRadixString(2).padLeft(16, '0'))
      .join(':');

  Ipv6Address operator &(Ipv6Address other) =>
      Ipv6Address(value & other.value);
  Ipv6Address operator |(Ipv6Address other) =>
      Ipv6Address(value | other.value);
  Ipv6Address get complement => Ipv6Address(~value);
  Ipv6Address operator +(BigInt delta) => Ipv6Address(value + delta);
  Ipv6Address operator -(BigInt delta) => Ipv6Address(value - delta);

  @override
  int compareTo(Ipv6Address other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) => other is Ipv6Address && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => canonical;

  bool _inRange(String base, int prefix) {
    final net = Ipv6Address.parse(base);
    final mask = Ipv6Prefix.maskForLength(prefix);
    return (this & mask) == (net & mask);
  }

  /// Clasificación según RFC 4291, RFC 4193, RFC 3849, RFC 6052, RFC 3056,
  /// RFC 8215.
  Ipv6Class get classification {
    if (value == BigInt.zero) return Ipv6Class.unspecified;
    if (value == BigInt.one) return Ipv6Class.loopback;
    if (_inRange('ff00::', 8)) return Ipv6Class.multicast;
    if (_inRange('fe80::', 10)) return Ipv6Class.linkLocal;
    if (_inRange('fc00::', 7)) return Ipv6Class.uniqueLocal;
    if (_inRange('::ffff:0:0', 96)) return Ipv6Class.ipv4Mapped;
    if (_inRange('64:ff9b::', 96)) return Ipv6Class.nat64WellKnown;
    if (_inRange('64:ff9b:1::', 48)) return Ipv6Class.nat64Local;
    if (_inRange('2001:db8::', 32)) return Ipv6Class.documentation;
    if (_inRange('2002::', 16)) return Ipv6Class.sixToFour;
    if (_inRange('2001::', 32)) return Ipv6Class.teredo;
    return Ipv6Class.globalUnicast;
  }
}

enum Ipv6Class {
  unspecified,
  loopback,
  linkLocal,
  uniqueLocal,
  multicast,
  ipv4Mapped,
  nat64WellKnown,
  nat64Local,
  documentation,
  sixToFour,
  teredo,
  globalUnicast,
}

extension Ipv6ClassLabel on Ipv6Class {
  String get label {
    switch (this) {
      case Ipv6Class.unspecified:
        return 'No especificada (::/128)';
      case Ipv6Class.loopback:
        return 'Loopback (::1/128)';
      case Ipv6Class.linkLocal:
        return 'Link-local (fe80::/10) — solo válida en el enlace';
      case Ipv6Class.uniqueLocal:
        return 'Unique Local Address / ULA (fc00::/7, RFC 4193) — equivalente a "privada"';
      case Ipv6Class.multicast:
        return 'Multicast (ff00::/8) — no existe broadcast en IPv6';
      case Ipv6Class.ipv4Mapped:
        return 'IPv4-mapped (::ffff:0:0/96) — solo representación interna, no rutear';
      case Ipv6Class.nat64WellKnown:
        return 'IPv4 embebida con Well-Known Prefix NAT64 (64:ff9b::/96, RFC 6052)';
      case Ipv6Class.nat64Local:
        return 'Prefijo local de traducción (64:ff9b:1::/48, RFC 8215)';
      case Ipv6Class.documentation:
        return 'Documentación (2001:db8::/32, RFC 3849)';
      case Ipv6Class.sixToFour:
        return '6to4 (2002::/16, RFC 3056) — legado, anycast desaconsejado (RFC 7526)';
      case Ipv6Class.teredo:
        return 'Teredo (2001::/32, RFC 4380) — legado';
      case Ipv6Class.globalUnicast:
        return 'Unicast global — potencialmente ruteable en Internet';
    }
  }
}

class Ipv6Prefix {
  final Ipv6Address address;
  final int length;

  Ipv6Prefix(this.address, this.length) {
    if (length < 0 || length > 128) {
      throw Ipv6FormatException('La longitud de prefijo IPv6 debe estar entre 0 y 128.');
    }
  }

  static Ipv6Prefix parse(String cidr) {
    final parts = cidr.trim().split('/');
    if (parts.length != 2) {
      throw Ipv6FormatException('Formato esperado: prefijo/longitud, ej. 2001:db8::/32');
    }
    final addr = Ipv6Address.parse(parts[0]);
    final len = int.tryParse(parts[1]);
    if (len == null) throw Ipv6FormatException('Prefijo inválido: "${parts[1]}".');
    return Ipv6Prefix(addr, len);
  }

  static Ipv6Address maskForLength(int p) {
    if (p == 0) return Ipv6Address(BigInt.zero);
    final full = (BigInt.one << 128) - BigInt.one;
    final hostBits = 128 - p;
    final mask = (full >> hostBits) << hostBits;
    return Ipv6Address(mask);
  }

  Ipv6Address get mask => maskForLength(length);
  Ipv6Address get networkStart => address & mask;
  Ipv6Address get networkEnd => networkStart | mask.complement;

  BigInt get totalAddresses => BigInt.two.pow(128 - length);

  bool contains(Ipv6Address ip) => (ip & mask) == networkStart;

  /// Cantidad de subprefijos /[childLength] contenidos en este prefijo.
  BigInt countOfSubPrefixes(int childLength) {
    if (childLength < length) {
      throw Ipv6FormatException('La subred hija debe ser más específica (mayor prefijo).');
    }
    return BigInt.two.pow(childLength - length);
  }

  List<Ipv6Prefix> splitToLength(int newLength, {int maxResults = 4096}) {
    final count = countOfSubPrefixes(newLength);
    if (count > BigInt.from(maxResults)) {
      throw Ipv6FormatException(
          'La división generaría ${count.toString()} subredes; supera el límite de visualización ($maxResults). Elige un prefijo más corto o un destino más específico.');
    }
    final blockSize = BigInt.two.pow(128 - newLength);
    final n = count.toInt();
    return List.generate(
      n,
      (i) => Ipv6Prefix(networkStart + (blockSize * BigInt.from(i)), newLength),
    );
  }

  @override
  String toString() => '${address.canonical}/$length';
}
