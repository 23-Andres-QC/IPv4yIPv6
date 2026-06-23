import 'package:flutter/material.dart';
import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../widgets/bit_view.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool isIpv6 = false;
  final addressCtrl = TextEditingController(text: '192.168.0.1');
  final prefixCtrl = TextEditingController(text: '24');
  String? error;

  Ipv4Prefix? v4result;
  Ipv6Prefix? v6result;

  void _calculate() {
    setState(() {
      error = null;
      v4result = null;
      v6result = null;
      final prefixLen = int.tryParse(prefixCtrl.text.trim());
      if (prefixLen == null) {
        error = 'La longitud de prefijo debe ser un número.';
        return;
      }
      try {
        if (isIpv6) {
          final addr = Ipv6Address.parse(addressCtrl.text);
          v6result = Ipv6Prefix(addr, prefixLen);
        } else {
          final addr = Ipv4Address.parse(addressCtrl.text);
          v4result = Ipv4Prefix(addr, prefixLen);
        }
      } catch (e) {
        error = e.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calculadora de direcciones', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Normalización, clasificación normativa, binario y rango de subred.'),
          const SizedBox(height: 16),
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('IPv4')),
                  ButtonSegment(value: true, label: Text('IPv6')),
                ],
                selected: {isIpv6},
                onSelectionChanged: (s) {
                  setState(() {
                    isIpv6 = s.first;
                    addressCtrl.text = isIpv6 ? '2001:db8:1200:12ab::' : '192.168.0.1';
                    prefixCtrl.text = isIpv6 ? '64' : '24';
                  });
                  _calculate();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 8),
              const Text('/', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: prefixCtrl,
                  decoration: const InputDecoration(labelText: 'Prefijo', border: OutlineInputBorder()),
                  onSubmitted: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _calculate, child: const Text('Calcular')),
            ],
          ),
          const SizedBox(height: 20),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            ),
          if (v4result != null) _buildIpv4Result(v4result!),
          if (v6result != null) _buildIpv6Result(v6result!),
        ],
      ),
    );
  }

  Widget _buildIpv4Result(Ipv4Prefix p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clasificación: ${p.address.classification.label}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            BitRow(label: 'Dirección', spans: ipv4BitSpans(p.address.value, p.length, prefixColor: Colors.blue), trailing: p.address.dotted),
            BitRow(label: 'Máscara', spans: ipv4BitSpans(p.mask.value, p.length, prefixColor: Colors.red), trailing: '${p.mask.dotted} = /${p.length}'),
            BitRow(label: 'Wildcard', spans: ipv4BitSpans(p.wildcard.value, 0, prefixColor: Colors.red, hostColor: Colors.black54), trailing: p.wildcard.dotted),
            const Divider(),
            BitRow(label: 'Red', spans: ipv4BitSpans(p.network.value, p.length, prefixColor: Colors.green), trailing: '${p.network.dotted}/${p.length}'),
            if (p.firstUsable != null)
              BitRow(label: 'HostMin', spans: ipv4BitSpans(p.firstUsable!.value, p.length, prefixColor: Colors.green), trailing: p.firstUsable!.dotted),
            if (p.lastUsable != null)
              BitRow(label: 'HostMax', spans: ipv4BitSpans(p.lastUsable!.value, p.length, prefixColor: Colors.green), trailing: p.lastUsable!.dotted),
            BitRow(label: 'Broadcast', spans: ipv4BitSpans(p.broadcastAddress.value, p.length, prefixColor: Colors.green), trailing: p.broadcastAddress.dotted),
            const SizedBox(height: 8),
            Text('Direcciones totales: ${p.totalAddresses}  •  Hosts utilizables: ${p.usableHostCount}'),
            if (p.length == 31) const Text('Caso especial RFC 3021: ambas direcciones del /31 son utilizables como host en enlaces punto a punto.'),
            if (p.length == 32) const Text('Host route /32: una sola dirección.'),
          ],
        ),
      ),
    );
  }

  Widget _buildIpv6Result(Ipv6Prefix p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clasificación: ${p.address.classification.label}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Canónico (RFC 5952): ${p.address.canonical}'),
            Text('Forma completa: ${p.address.fullForm}'),
            if (p.address.classification == Ipv6Class.ipv4Mapped || p.address.classification == Ipv6Class.nat64WellKnown)
              Text('Forma mixta: ${p.address.mixedFormIfApplicable}'),
            const Divider(),
            BitRow(label: 'Dirección', spans: ipv6BitSpans(p.address.value, p.length, prefixColor: Colors.blue)),
            BitRow(label: 'Máscara', spans: ipv6BitSpans(p.mask.value, p.length, prefixColor: Colors.red)),
            const Divider(),
            Text('Inicio del prefijo: ${p.networkStart.canonical}'),
            Text('Fin del prefijo: ${p.networkEnd.canonical}'),
            Text('Direcciones totales: ${p.totalAddresses}'),
            const Text('IPv6 no tiene broadcast: la difusión grupal se resuelve con multicast (RFC 4291) y Neighbor Discovery (RFC 4861).'),
          ],
        ),
      ),
    );
  }
}
