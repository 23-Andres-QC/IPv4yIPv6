import 'ipv4.dart';
import 'ipv6.dart';

class Ipv4SubnetRow {
  final Ipv4Prefix prefix;
  Ipv4SubnetRow(this.prefix);

  Ipv4Address get network => prefix.network;
  Ipv4Address? get hostMin => prefix.firstUsable;
  Ipv4Address? get hostMax => prefix.lastUsable;
  Ipv4Address get broadcast => prefix.broadcastAddress;
  int get hostCount => prefix.usableHostCount;
  Ipv4Class get classification => network.classification;
}

class Ipv4SubnetPlan {
  final List<Ipv4SubnetRow> rows;
  final int newLength;
  final int deliveredCount;
  final int? requestedCount;
  final int? requestedHosts;
  Ipv4SubnetPlan({
    required this.rows,
    required this.newLength,
    required this.deliveredCount,
    this.requestedCount,
    this.requestedHosts,
  });

  bool get wasRounded =>
      requestedCount != null && requestedCount != deliveredCount;
}

class Ipv4SubnettingException implements Exception {
  final String message;
  Ipv4SubnettingException(this.message);
  @override
  String toString() => message;
}

class Ipv4Subnetting {
  static List<Ipv4SubnetRow> transitionMask(
    Ipv4Address address,
    int originalLength,
    int newLength, {
    int maxResults = 4096,
  }) {
    if (newLength < 0 || newLength > 32) {
      throw Ipv4SubnettingException(
        'La nueva longitud debe estar entre 0 y 32.',
      );
    }
    final original = Ipv4Prefix(address, originalLength);
    if (newLength == originalLength) {
      return [Ipv4SubnetRow(original)];
    }
    if (newLength > originalLength) {
      final count = 1 << (newLength - originalLength);
      if (count > maxResults) {
        throw Ipv4SubnettingException(
          'La división de /$originalLength a /$newLength generaría $count subredes; '
          'supera el límite de visualización ($maxResults).',
        );
      }
      return original.splitToLength(newLength).map(Ipv4SubnetRow.new).toList();
    }
    final supernet = Ipv4Prefix(address, newLength);
    return [Ipv4SubnetRow(Ipv4Prefix(supernet.network, newLength))];
  }

  static List<Ipv4SubnetRow> splitFixed(Ipv4Prefix base, int count) {
    return base.splitInto(count).map(Ipv4SubnetRow.new).toList();
  }

  static int extraBitsForCount(int desiredCount) {
    if (desiredCount < 1) {
      throw Ipv4SubnettingException(
        'La cantidad de subredes debe ser al menos 1.',
      );
    }
    var bits = 0;
    var capacity = 1;
    while (capacity < desiredCount) {
      capacity <<= 1;
      bits++;
    }
    return bits;
  }

  static Ipv4SubnetPlan byDesiredSubnetCount(
    Ipv4Prefix base,
    int desiredCount, {
    int maxResults = 4096,
  }) {
    final extraBits = extraBitsForCount(desiredCount);
    final newLength = base.length + extraBits;
    if (newLength > 32) {
      throw Ipv4SubnettingException(
        'No es posible crear $desiredCount subredes a partir de ${base.toString()}: '
        'se necesitarían ${base.length + extraBits} bits de prefijo, más de los 32 disponibles.',
      );
    }
    final deliveredCount = 1 << extraBits;
    if (deliveredCount > maxResults) {
      throw Ipv4SubnettingException(
        'Se generarían $deliveredCount subredes (/$newLength); supera el límite de visualización ($maxResults).',
      );
    }
    final rows = base.splitToLength(newLength).map(Ipv4SubnetRow.new).toList();
    return Ipv4SubnetPlan(
      rows: rows,
      newLength: newLength,
      requestedCount: desiredCount,
      deliveredCount: deliveredCount,
    );
  }

  static Ipv4SubnetPlan byHostsPerSubnet(
    Ipv4Prefix base,
    int hostsPerSubnet, {
    int maxResults = 4096,
  }) {
    final neededLength = _smallestPrefixForHosts(hostsPerSubnet);
    if (neededLength < base.length) {
      throw Ipv4SubnettingException(
        'La red base ${base.toString()} no alcanza para $hostsPerSubnet hosts en una sola subred '
        '(se requeriría /$neededLength, una red mayor que la base).',
      );
    }
    final deliveredCount = 1 << (neededLength - base.length);
    if (deliveredCount > maxResults) {
      throw Ipv4SubnettingException(
        'Con /$neededLength se generarían $deliveredCount subredes; supera el límite de visualización ($maxResults).',
      );
    }
    final rows = base
        .splitToLength(neededLength)
        .map(Ipv4SubnetRow.new)
        .toList();
    return Ipv4SubnetPlan(
      rows: rows,
      newLength: neededLength,
      requestedHosts: hostsPerSubnet,
      deliveredCount: deliveredCount,
    );
  }

  static List<Ipv4Prefix> vlsm(Ipv4Prefix base, List<int> hostRequirements) {
    final indexed = <MapEntry<int, int>>[];
    for (var i = 0; i < hostRequirements.length; i++) {
      indexed.add(MapEntry(i, hostRequirements[i]));
    }
    final ordered = [...indexed]..sort((a, b) => b.value.compareTo(a.value));

    var cursor = base.network;
    final end = base.broadcastAddress;
    final resultByIndex = <int, Ipv4Prefix>{};

    for (final entry in ordered) {
      final hosts = entry.value;
      final neededLength = _smallestPrefixForHosts(hosts);
      final blockSize = 1 << (32 - neededLength);
      final aligned = ((cursor.value + blockSize - 1) ~/ blockSize) * blockSize;
      final candidate = Ipv4Address.fromInt(aligned);
      final candidatePrefix = Ipv4Prefix(candidate, neededLength);
      if (candidatePrefix.broadcastAddress.value > end.value) {
        throw Ipv4SubnettingException(
          'No hay espacio suficiente en ${base.toString()} para asignar $hosts hosts '
          '(se requiere /$neededLength).',
        );
      }
      resultByIndex[entry.key] = candidatePrefix;
      cursor = candidatePrefix.broadcastAddress + 1;
    }
    return List.generate(hostRequirements.length, (i) => resultByIndex[i]!);
  }

  static int _smallestPrefixForHosts(int hosts) {
    if (hosts <= 0) {
      throw Ipv4SubnettingException(
        'La cantidad de hosts requerida debe ser mayor que 0.',
      );
    }
    if (hosts == 1) return 32;
    if (hosts == 2) return 31;
    var needed = hosts + 2;
    var length = 32;
    var size = 1;
    while (size < needed) {
      size <<= 1;
      length--;
    }
    return length;
  }

  static List<Ipv4Prefix> aggregate(List<Ipv4Prefix> input) {
    var current = [...input]
      ..sort((a, b) => a.network.value.compareTo(b.network.value));
    var changed = true;
    while (changed) {
      changed = false;
      final next = <Ipv4Prefix>[];
      var i = 0;
      while (i < current.length) {
        if (i + 1 < current.length) {
          final a = current[i];
          final b = current[i + 1];
          if (a.length == b.length &&
              a.length > 0 &&
              b.network.value == a.network.value + (1 << (32 - a.length)) &&
              (a.network.value % (1 << (32 - (a.length - 1)))) == 0) {
            next.add(Ipv4Prefix(a.network, a.length - 1));
            i += 2;
            changed = true;
            continue;
          }
        }
        next.add(current[i]);
        i += 1;
      }
      current = next;
    }
    return current;
  }
}

class Ipv6SubnettingException implements Exception {
  final String message;
  Ipv6SubnettingException(this.message);
  @override
  String toString() => message;
}

class Ipv6Subnetting {
  static List<Ipv6Prefix> transitionMask(
    Ipv6Address address,
    int originalLength,
    int newLength, {
    int maxResults = 4096,
  }) {
    if (originalLength < 0 || originalLength > 128) {
      throw Ipv6FormatException(
        'La longitud de prefijo IPv6 debe estar entre 0 y 128.',
      );
    }
    if (newLength < 0 || newLength > 128) {
      throw Ipv6SubnettingException(
        'La nueva longitud debe estar entre 0 y 128.',
      );
    }
    if (newLength == originalLength) {
      return [Ipv6Prefix(address, originalLength)];
    }
    if (newLength > originalLength) {
      final original = Ipv6Prefix(address, originalLength);
      return original.splitToLength(newLength, maxResults: maxResults);
    }
    final supernet = Ipv6Prefix(address, newLength);
    return [Ipv6Prefix(supernet.networkStart, newLength)];
  }

  static List<Ipv6Prefix> allocateSites(Ipv6Prefix site, int branchLength) =>
      site.splitToLength(branchLength);

  static List<Ipv6Prefix> allocateLans(
    Ipv6Prefix branch, {
    int lanLength = 64,
  }) => branch.splitToLength(lanLength);

  static int extraBitsForCount(int desiredCount) {
    if (desiredCount < 1) {
      throw Ipv6SubnettingException(
        'La cantidad de subredes debe ser al menos 1.',
      );
    }
    var bits = 0;
    var capacity = 1;
    while (capacity < desiredCount) {
      capacity <<= 1;
      bits++;
    }
    return bits;
  }

  static Ipv6SubnetPlan byDesiredSubnetCount(
    Ipv6Prefix base,
    int desiredCount, {
    int maxResults = 4096,
  }) {
    final extraBits = extraBitsForCount(desiredCount);
    final newLength = base.length + extraBits;
    if (newLength > 128) {
      throw Ipv6SubnettingException(
        'No es posible crear $desiredCount subredes a partir de ${base.toString()}: '
        'se necesitarían $newLength bits de prefijo, más de los 128 disponibles.',
      );
    }
    final deliveredCount = 1 << extraBits;
    if (deliveredCount > maxResults) {
      throw Ipv6SubnettingException(
        'Se generarían $deliveredCount subredes (/$newLength); supera el límite de visualización ($maxResults).',
      );
    }
    final rows = base.splitToLength(newLength, maxResults: maxResults);
    return Ipv6SubnetPlan(
      rows: rows,
      newLength: newLength,
      requestedCount: desiredCount,
      deliveredCount: deliveredCount,
    );
  }

  static List<Ipv6Prefix> vlsm(
    Ipv6Prefix base,
    List<BigInt> addressRequirements,
  ) {
    final indexed = <MapEntry<int, BigInt>>[];
    for (var i = 0; i < addressRequirements.length; i++) {
      indexed.add(MapEntry(i, addressRequirements[i]));
    }
    final ordered = [...indexed]..sort((a, b) => b.value.compareTo(a.value));

    var cursor = base.networkStart;
    final end = base.networkEnd;
    final resultByIndex = <int, Ipv6Prefix>{};

    for (final entry in ordered) {
      final addresses = entry.value;
      final neededLength = _smallestPrefixForAddresses(addresses);
      if (neededLength < base.length) {
        throw Ipv6SubnettingException(
          'La red base ${base.toString()} no alcanza para ${addresses.toString()} direcciones '
          '(se requeriría /$neededLength, una red mayor que la base).',
        );
      }
      final blockSize = BigInt.two.pow(128 - neededLength);
      final aligned =
          ((cursor.value + blockSize - BigInt.one) ~/ blockSize) * blockSize;
      final candidate = Ipv6Address(aligned);
      final candidatePrefix = Ipv6Prefix(candidate, neededLength);
      if (candidatePrefix.networkEnd.value > end.value) {
        throw Ipv6SubnettingException(
          'No hay espacio suficiente en ${base.toString()} para asignar ${addresses.toString()} direcciones '
          '(se requiere /$neededLength).',
        );
      }
      resultByIndex[entry.key] = candidatePrefix;
      cursor = candidatePrefix.networkEnd + BigInt.one;
    }
    return List.generate(addressRequirements.length, (i) => resultByIndex[i]!);
  }

  static int _smallestPrefixForAddresses(BigInt addresses) {
    if (addresses <= BigInt.zero) {
      throw Ipv6SubnettingException(
        'La cantidad de direcciones requerida debe ser mayor que 0.',
      );
    }
    var length = 128;
    var size = BigInt.one;
    while (size < addresses) {
      size <<= 1;
      length--;
      if (length < 0) {
        throw Ipv6SubnettingException(
          'La cantidad de direcciones requerida supera el espacio IPv6.',
        );
      }
    }
    return length;
  }
}

class Ipv6SubnetPlan {
  final List<Ipv6Prefix> rows;
  final int newLength;
  final int deliveredCount;
  final int? requestedCount;
  Ipv6SubnetPlan({
    required this.rows,
    required this.newLength,
    required this.deliveredCount,
    this.requestedCount,
  });

  bool get wasRounded =>
      requestedCount != null && requestedCount != deliveredCount;
}
