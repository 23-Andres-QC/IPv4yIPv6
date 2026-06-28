import 'package:flutter/material.dart';
import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../core/connectivity.dart';

class _InputException implements Exception {
  final String message;
  _InputException(this.message);
  @override
  String toString() => message;
}

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});
  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _EndpointInput {
  bool isIpv6 = false;
  final addressCtrl = TextEditingController(text: '192.168.0.10');
  final prefixCtrl = TextEditingController(text: '24');
  bool dualStack = false;
  bool hasTranslator = false;

  void dispose() {
    addressCtrl.dispose();
    prefixCtrl.dispose();
  }
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final a = _EndpointInput();
  final b = _EndpointInput()
    ..addressCtrl.text = '203.0.113.5'
    ..prefixCtrl.text = '28';

  ConnectivityResult? result;
  String? error;
  List<String> warnings = [];

  @override
  void dispose() {
    a.dispose();
    b.dispose();
    super.dispose();
  }

  void _clearResult() {
    if (error == null && result == null && warnings.isEmpty) {
      return;
    }
    setState(() {
      error = null;
      result = null;
      warnings = [];
    });
  }

  void _evaluate() {
    setState(() {
      error = null;
      result = null;
      warnings = [];
      try {
        final endpointA = _build(a);
        final endpointB = _build(b);
        result = ConnectivityEngine.evaluate(endpointA, endpointB);
        warnings = [
          ..._warningsFor(endpointA, 'Extremo A'),
          ..._warningsFor(endpointB, 'Extremo B'),
        ];
      } catch (e) {
        error = e.toString();
      }
    });
  }

  int _parsePrefix(String text, {required bool ipv6}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      throw _InputException('El prefijo no puede estar vacío.');
    }
    final value = raw.startsWith('/') ? raw.substring(1).trim() : raw;
    final len = int.tryParse(value);
    if (len == null) {
      throw _InputException('El prefijo debe ser un número entero.');
    }
    final max = ipv6 ? 128 : 32;
    if (len < 0 || len > max) {
      throw _InputException('El prefijo debe estar entre 0 y $max.');
    }
    return len;
  }

  ConnectivityEndpoint _build(_EndpointInput e) {
    if (e.isIpv6) {
      final addr = Ipv6Address.parse(e.addressCtrl.text);
      final len = _parsePrefix(e.prefixCtrl.text, ipv6: true);
      return ConnectivityEndpoint(
        v6: Ipv6Prefix(addr, len),
        dualStack: e.dualStack,
        hasNat64Or6: e.hasTranslator,
      );
    }
    final addr = Ipv4Address.parse(e.addressCtrl.text);
    final len = _parsePrefix(e.prefixCtrl.text, ipv6: false);
    return ConnectivityEndpoint(
      v4: Ipv4Prefix(addr, len),
      dualStack: e.dualStack,
      hasNat64Or6: e.hasTranslator,
    );
  }

  List<String> _warningsFor(ConnectivityEndpoint endpoint, String label) {
    final out = <String>[];
    final v4 = endpoint.v4;
    if (v4 != null) {
      switch (v4.address.classification) {
        case Ipv4Class.unspecified:
          out.add(
            '$label: 0.0.0.0 es no especificada; no representa un destino de comunicación normal.',
          );
          break;
        case Ipv4Class.loopback:
          out.add(
            '$label: dirección loopback; solo es válida dentro del propio equipo.',
          );
          break;
        case Ipv4Class.private:
          out.add(
            '$label: IPv4 privada; puede rutearse internamente, pero no directamente en Internet.',
          );
          break;
        case Ipv4Class.linkLocal:
          out.add(
            '$label: IPv4 link-local/APIPA; solo aplica al enlace local.',
          );
          break;
        case Ipv4Class.documentation:
          out.add(
            '$label: IPv4 de documentación; útil para ejemplos, no para conectividad real.',
          );
          break;
        case Ipv4Class.multicast:
          out.add(
            '$label: IPv4 multicast; no representa un host unicast normal.',
          );
          break;
        case Ipv4Class.broadcastLimited:
          out.add('$label: broadcast limitado; no representa un host unicast.');
          break;
        case Ipv4Class.reserved:
          out.add('$label: IPv4 reservada; no debe asumirse ruteable.');
          break;
        case Ipv4Class.sharedCgnat:
        case Ipv4Class.benchmarking:
        case Ipv4Class.global:
          break;
      }
    }

    final v6 = endpoint.v6;
    if (v6 != null) {
      switch (v6.address.classification) {
        case Ipv6Class.unspecified:
          out.add(
            '$label: :: es no especificada; no representa un destino de comunicación normal.',
          );
          break;
        case Ipv6Class.loopback:
          out.add(
            '$label: dirección loopback; solo es válida dentro del propio equipo.',
          );
          break;
        case Ipv6Class.linkLocal:
          out.add(
            '$label: IPv6 link-local; requiere mismo enlace y normalmente zona/interfaz.',
          );
          break;
        case Ipv6Class.uniqueLocal:
          out.add(
            '$label: ULA; puede rutearse internamente, pero no directamente en Internet.',
          );
          break;
        case Ipv6Class.multicast:
          out.add(
            '$label: IPv6 multicast; no representa un host unicast normal.',
          );
          break;
        case Ipv6Class.documentation:
          out.add(
            '$label: IPv6 de documentación; útil para ejemplos, no para conectividad real.',
          );
          break;
        case Ipv6Class.ipv4Mapped:
        case Ipv6Class.nat64WellKnown:
        case Ipv6Class.nat64Local:
        case Ipv6Class.sixToFour:
        case Ipv6Class.teredo:
        case Ipv6Class.globalUnicast:
          break;
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conectividad entre dos extremos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Distingue mismo enlace, ruteo entre subredes, dual-stack declarado y traducción/túnel declarado.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _endpointCard('Extremo A', a)),
              const SizedBox(width: 16),
              Expanded(child: _endpointCard('Extremo B', b)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _evaluate,
            child: const Text('Evaluar conectividad'),
          ),
          const SizedBox(height: 20),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revisa los datos de conectividad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(error!),
                  ],
                ),
              ),
            ),
          if (result != null)
            Card(
              color: _colorForKind(result!.kind, context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final d in result!.details)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(d),
                      ),
                    if (warnings.isNotEmpty) const Divider(),
                    if (warnings.isNotEmpty)
                      const Text(
                        'Advertencias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    for (final warning in warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(warning),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForKind(ConnectivityKind k, BuildContext context) {
    switch (k) {
      case ConnectivityKind.sameLinkDirect:
      case ConnectivityKind.dualStackCommonFamily:
        return Colors.green.shade50;
      case ConnectivityKind.routedSameFamily:
        return Colors.blue.shade50;
      case ConnectivityKind.translatedNat64:
      case ConnectivityKind.translatedSiit:
      case ConnectivityKind.translated6to4:
        return Colors.amber.shade50;
      case ConnectivityKind.noPath:
        return Colors.red.shade50;
    }
  }

  Widget _endpointCard(String title, _EndpointInput e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('IPv4')),
                    ButtonSegment(value: true, label: Text('IPv6')),
                  ],
                  selected: {e.isIpv6},
                  onSelectionChanged: (s) {
                    setLocal(() {
                      e.isIpv6 = s.first;
                      e.addressCtrl.text = e.isIpv6
                          ? '2001:db8:1::1'
                          : '192.168.0.10';
                      e.prefixCtrl.text = e.isIpv6 ? '64' : '24';
                    });
                    _clearResult();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _clearResult(),
                  onSubmitted: (_) => _evaluate(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.prefixCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prefijo',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _clearResult(),
                  onSubmitted: (_) => _evaluate(),
                ),
                CheckboxListTile(
                  value: e.dualStack,
                  onChanged: (v) {
                    setLocal(() => e.dualStack = v ?? false);
                    _clearResult();
                  },
                  title: const Text('Dual-stack declarado'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: e.hasTranslator,
                  onChanged: (v) {
                    setLocal(() => e.hasTranslator = v ?? false);
                    _clearResult();
                  },
                  title: const Text('Traducción/túnel declarado'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
