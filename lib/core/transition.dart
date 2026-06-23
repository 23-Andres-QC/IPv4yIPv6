import 'ipv4.dart';
import 'ipv6.dart';

class TransitionException implements Exception {
  final String message;
  TransitionException(this.message);
  @override
  String toString() => message;
}

/// Resultado de una transformación, con el texto resultante y advertencias
/// normativas relevantes (p. ej. uso indebido del Well-Known Prefix).
class TransitionResult {
  final String resultText;
  final String method;
  final List<String> notes;
  TransitionResult(this.resultText, this.method, {this.notes = const []});
}

/// Longitudes de prefijo permitidas por RFC 6052 §2.2 para incrustar IPv4.
const List<int> rfc6052AllowedPrefixLengths = [32, 40, 48, 56, 64, 96];

class TransitionEngine {
  /// IPv4-mapped IPv6 (RFC 4291 §2.5.5.2): ::ffff:a.b.c.d — solo
  /// representación interna de sockets, no es mecanismo de tránsito.
  static TransitionResult ipv4ToMapped(Ipv4Address ipv4) {
    final v6 = Ipv6Address.fromIpv4Mapped(ipv4);
    return TransitionResult(
      v6.mixedFormIfApplicable,
      'IPv4-mapped (RFC 4291 §2.5.5.2)',
      notes: [
        'Uso: representación de un nodo IPv4 dentro de una pila/API dual-stack.',
        'No debe aparecer en el Internet público (RFC 5156) ni se debe rutear como mecanismo de transición.',
      ],
    );
  }

  static Ipv4Address? mappedToIpv4(Ipv6Address v6) {
    if (v6.classification != Ipv6Class.ipv4Mapped) return null;
    return Ipv4Address.fromInt((v6.value & BigInt.from(0xFFFFFFFF)).toInt());
  }

  /// Incrustación algorítmica RFC 6052 §2.2 con prefijo bien conocido o de
  /// red, longitudes permitidas {32,40,48,56,64,96}. Inserta el octeto nulo
  /// 'u' en los bits 64-71 cuando el prefijo es menor que 96.
  static TransitionResult embedRfc6052(
    Ipv4Address ipv4,
    Ipv6Address prefixAddress,
    int prefixLength,
  ) {
    if (!rfc6052AllowedPrefixLengths.contains(prefixLength)) {
      throw TransitionException(
          'RFC 6052 solo permite PL ∈ {32,40,48,56,64,96}; recibido /$prefixLength.');
    }
    final notes = <String>[];
    final wkp = Ipv6Prefix.parse('64:ff9b::/96');
    final isWkp = (prefixAddress & wkp.mask) == wkp.networkStart && prefixLength == 96;
    if (isWkp && ipv4.classification != Ipv4Class.global) {
      notes.add(
          'Advertencia RFC 6052 §3.1: el Well-Known Prefix 64:ff9b::/96 NO debe usarse '
          'con direcciones IPv4 no globales (ej. RFC 1918). Esos paquetes deberían descartarse. '
          'Si necesitas representar una IPv4 privada, usa el prefijo local 64:ff9b:1::/48 (RFC 8215) '
          'o un Network-Specific Prefix propio.');
    }

    final ipv4Bits = BigInt.from(ipv4.value); // 32 bits
    final prefixMask = Ipv6Prefix.maskForLength(prefixLength);
    final prefixBits = prefixAddress.value & prefixMask.value;
    final result = prefixBits | _embedV4Bits(ipv4Bits, prefixLength);
    final v6 = Ipv6Address(result);
    return TransitionResult(
      '${v6.canonical}  (mixta: ${_mixedRfc6052(v6, prefixLength)})',
      'RFC 6052 — Incrustación algorítmica de IPv4 en IPv6 (PL=/$prefixLength)',
      notes: notes,
    );
  }

  static String _mixedRfc6052(Ipv6Address v6, int prefixLength) {
    if (prefixLength == 96) return v6.mixedFormIfApplicable;
    return v6.canonical;
  }

  /// Extracción inversa RFC 6052 §2.3.
  static Ipv4Address extractRfc6052(Ipv6Address v6, int prefixLength) {
    if (!rfc6052AllowedPrefixLengths.contains(prefixLength)) {
      throw TransitionException(
          'RFC 6052 solo permite PL ∈ {32,40,48,56,64,96}; recibido /$prefixLength.');
    }
    if (prefixLength == 96) {
      return Ipv4Address.fromInt((v6.value & BigInt.from(0xFFFFFFFF)).toInt());
    }
    final v4Bits = _extractV4Bits(v6.value, prefixLength);
    return Ipv4Address.fromInt(v4Bits.toInt());
  }

  /// Divide los 32 bits de la IPv4 alrededor del octeto nulo 'u' (bits
  /// 64-71) según la tabla de RFC 6052 §2.2, y los coloca en su posición
  /// dentro del entero de 128 bits. La parte alta (64-PL bits) queda justo
  /// antes del octeto u y la parte baja justo después de él.
  static BigInt _embedV4Bits(BigInt ipv4Bits, int prefixLength) {
    final highBits = 64 - prefixLength;
    final lowBits = 32 - highBits;
    BigInt acc = BigInt.zero;
    if (highBits > 0) {
      final highPart = (ipv4Bits >> lowBits) & ((BigInt.one << highBits) - BigInt.one);
      acc |= highPart << 64;
    }
    if (lowBits > 0) {
      final lowPart = ipv4Bits & ((BigInt.one << lowBits) - BigInt.one);
      acc |= lowPart << (88 - prefixLength);
    }
    return acc;
  }

  static BigInt _extractV4Bits(BigInt v6Value, int prefixLength) {
    final highBits = 64 - prefixLength;
    final lowBits = 32 - highBits;
    BigInt highPart = BigInt.zero, lowPart = BigInt.zero;
    if (highBits > 0) {
      highPart = (v6Value >> 64) & ((BigInt.one << highBits) - BigInt.one);
    }
    if (lowBits > 0) {
      lowPart = (v6Value >> (88 - prefixLength)) & ((BigInt.one << lowBits) - BigInt.one);
    }
    return (highPart << lowBits) | lowPart;
  }

  /// 6to4 (RFC 3056): prefijo de sitio /48, formado por 2002 seguido de la IPv4 en hexadecimal.
  static TransitionResult ipv4ToSixToFour(Ipv4Address ipv4) {
    final v4hex = BigInt.from(ipv4.value);
    final prefixValue = (BigInt.parse('2002', radix: 16) << 112) | (v4hex << 80);
    final v6 = Ipv6Address(prefixValue);
    return TransitionResult(
      '${v6.canonical}/48',
      '6to4 (RFC 3056)',
      notes: [
        'Mecanismo de transición legado: requiere una IPv4 pública única para el sitio.',
        'RFC 7526 desaconseja el modo anycast de 6to4 para despliegues nuevos; úsalo solo como referencia histórica o de laboratorio.',
      ],
    );
  }

  static Ipv4Address? sixToFourToIpv4(Ipv6Address v6) {
    if (v6.classification != Ipv6Class.sixToFour) return null;
    final v4Bits = (v6.value >> 80) & BigInt.from(0xFFFFFFFF);
    return Ipv4Address.fromInt(v4Bits.toInt());
  }
}
