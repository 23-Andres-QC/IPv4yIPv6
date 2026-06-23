import 'package:flutter/material.dart';
import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../core/connectivity.dart';

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
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final a = _EndpointInput();
  final b = _EndpointInput()
    ..addressCtrl.text = '203.0.113.5'
    ..prefixCtrl.text = '28';

  ConnectivityResult? result;
  String? error;

  void _evaluate() {
    setState(() {
      error = null;
      result = null;
      try {
        final endpointA = _build(a);
        final endpointB = _build(b);
        result = ConnectivityEngine.evaluate(endpointA, endpointB);
      } catch (e) {
        error = e.toString();
      }
    });
  }

  ConnectivityEndpoint _build(_EndpointInput e) {
    if (e.isIpv6) {
      final addr = Ipv6Address.parse(e.addressCtrl.text);
      final len = int.parse(e.prefixCtrl.text.trim());
      return ConnectivityEndpoint(v6: Ipv6Prefix(addr, len), dualStack: e.dualStack, hasNat64Or6: e.hasTranslator);
    }
    final addr = Ipv4Address.parse(e.addressCtrl.text);
    final len = int.parse(e.prefixCtrl.text.trim());
    return ConnectivityEndpoint(v4: Ipv4Prefix(addr, len), dualStack: e.dualStack, hasNat64Or6: e.hasTranslator);
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
          Text('Conectividad entre dos extremos', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Distingue mismo enlace, ruteo entre subredes, dual-stack y traducción/túnel (NAT64, SIIT, 6to4, DS-Lite, MAP).'),
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
          FilledButton(onPressed: _evaluate, child: const Text('Evaluar conectividad')),
          const SizedBox(height: 20),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            ),
          if (result != null)
            Card(
              color: _colorForKind(result!.kind, context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    for (final d in result!.details) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(d)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('IPv4')),
                    ButtonSegment(value: true, label: Text('IPv6')),
                  ],
                  selected: {e.isIpv6},
                  onSelectionChanged: (s) => setLocal(() {
                    e.isIpv6 = s.first;
                    e.addressCtrl.text = e.isIpv6 ? '2001:db8:1::1' : '192.168.0.10';
                    e.prefixCtrl.text = e.isIpv6 ? '64' : '24';
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.addressCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.prefixCtrl,
                  decoration: const InputDecoration(labelText: 'Prefijo', border: OutlineInputBorder()),
                ),
                CheckboxListTile(
                  value: e.dualStack,
                  onChanged: (v) => setLocal(() => e.dualStack = v ?? false),
                  title: const Text('Dual-stack (IPv4+IPv6 nativos)'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: e.hasTranslator,
                  onChanged: (v) => setLocal(() => e.hasTranslator = v ?? false),
                  title: const Text('Tiene traductor/túnel disponible (NAT64, SIIT, DS-Lite, MAP...)'),
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
