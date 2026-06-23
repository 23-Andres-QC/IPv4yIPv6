import 'package:flutter/material.dart';
import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../core/transition.dart';

enum _Direction { v4ToV6, v6ToV4 }

enum _Method { mapped, rfc6052, sixToFour }

class Ipv4ToIpv6Screen extends StatefulWidget {
  const Ipv4ToIpv6Screen({super.key});
  @override
  State<Ipv4ToIpv6Screen> createState() => _Ipv4ToIpv6ScreenState();
}

class _Ipv4ToIpv6ScreenState extends State<Ipv4ToIpv6Screen> {
  _Direction direction = _Direction.v4ToV6;
  _Method method = _Method.rfc6052;

  final ipv4Ctrl = TextEditingController(text: '192.0.2.33');
  final ipv6Ctrl = TextEditingController(text: '64:ff9b::192.0.2.33');
  final prefixAddrCtrl = TextEditingController(text: '64:ff9b::');
  final prefixLenCtrl = TextEditingController(text: '96');

  String? error;
  List<String> resultLines = [];
  List<String> notes = [];

  void _run() {
    setState(() {
      error = null;
      resultLines = [];
      notes = [];
      try {
        if (direction == _Direction.v4ToV6) {
          final ipv4 = Ipv4Address.parse(ipv4Ctrl.text);
          switch (method) {
            case _Method.mapped:
              final r = TransitionEngine.ipv4ToMapped(ipv4);
              resultLines = [r.resultText];
              notes = [r.method, ...r.notes];
              break;
            case _Method.rfc6052:
              final prefixAddr = Ipv6Address.parse(prefixAddrCtrl.text);
              final pl = int.parse(prefixLenCtrl.text.trim());
              final r = TransitionEngine.embedRfc6052(ipv4, prefixAddr, pl);
              resultLines = [r.resultText];
              notes = [r.method, ...r.notes];
              break;
            case _Method.sixToFour:
              final r = TransitionEngine.ipv4ToSixToFour(ipv4);
              resultLines = [r.resultText];
              notes = [r.method, ...r.notes];
              break;
          }
        } else {
          final v6 = Ipv6Address.parse(ipv6Ctrl.text);
          final cls = v6.classification;
          resultLines.add('Clasificación detectada: ${cls.label}');
          if (cls == Ipv6Class.ipv4Mapped) {
            final v4 = TransitionEngine.mappedToIpv4(v6)!;
            resultLines.add('IPv4 extraída (mapped): ${v4.dotted}');
          } else if (cls == Ipv6Class.nat64WellKnown) {
            final v4 = TransitionEngine.extractRfc6052(v6, 96);
            resultLines.add('IPv4 extraída (RFC 6052, WKP /96): ${v4.dotted}');
          } else if (cls == Ipv6Class.sixToFour) {
            final v4 = TransitionEngine.sixToFourToIpv4(v6);
            resultLines.add('IPv4 del sitio 6to4: ${v4?.dotted}');
          } else {
            final pl = int.tryParse(prefixLenCtrl.text.trim());
            if (pl != null && rfc6052AllowedPrefixLengths.contains(pl)) {
              try {
                final v4 = TransitionEngine.extractRfc6052(v6, pl);
                resultLines.add('IPv4 extraída con prefijo /$pl (RFC 6052, prefijo de red específico): ${v4.dotted}');
              } catch (_) {}
            }
            notes.add('Esta dirección no usa un mecanismo de incrustación estándar reconocido automáticamente; '
                'si corresponde a un prefijo de red específico RFC 6052, indica su longitud arriba.');
          }
        }
      } catch (e) {
        error = e.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transición IPv4 ↔ IPv6', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('IPv4-mapped (RFC 4291), incrustación RFC 6052 (NAT64/SIIT) y 6to4 (RFC 3056).'),
          const SizedBox(height: 16),
          SegmentedButton<_Direction>(
            segments: const [
              ButtonSegment(value: _Direction.v4ToV6, label: Text('IPv4 → IPv6')),
              ButtonSegment(value: _Direction.v6ToV4, label: Text('IPv6 → IPv4')),
            ],
            selected: {direction},
            onSelectionChanged: (s) => setState(() => direction = s.first),
          ),
          const SizedBox(height: 16),
          if (direction == _Direction.v4ToV6) ..._buildV4ToV6Inputs() else ..._buildV6ToV4Inputs(),
          const SizedBox(height: 16),
          FilledButton(onPressed: _run, child: const Text('Transformar')),
          const SizedBox(height: 20),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            ),
          if (resultLines.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in resultLines)
                      SelectableText(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold)),
                    if (notes.isNotEmpty) const Divider(),
                    for (final n in notes) Padding(padding: const EdgeInsets.only(top: 4), child: Text(n)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildV4ToV6Inputs() {
    return [
      TextField(
        controller: ipv4Ctrl,
        decoration: const InputDecoration(labelText: 'Dirección IPv4', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      SegmentedButton<_Method>(
        segments: const [
          ButtonSegment(value: _Method.mapped, label: Text('IPv4-mapped')),
          ButtonSegment(value: _Method.rfc6052, label: Text('RFC 6052')),
          ButtonSegment(value: _Method.sixToFour, label: Text('6to4')),
        ],
        selected: {method},
        onSelectionChanged: (s) => setState(() => method = s.first),
      ),
      if (method == _Method.rfc6052) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: prefixAddrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prefijo IPv6 (WKP 64:ff9b:: o tu NSP)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int>(
                initialValue: int.tryParse(prefixLenCtrl.text) ?? 96,
                decoration: const InputDecoration(labelText: 'PL', border: OutlineInputBorder()),
                items: rfc6052AllowedPrefixLengths
                    .map((p) => DropdownMenuItem(value: p, child: Text('/$p')))
                    .toList(),
                onChanged: (v) => setState(() => prefixLenCtrl.text = '$v'),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildV6ToV4Inputs() {
    return [
      TextField(
        controller: ipv6Ctrl,
        decoration: const InputDecoration(labelText: 'Dirección IPv6', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: 200,
        child: DropdownButtonFormField<int>(
          initialValue: int.tryParse(prefixLenCtrl.text) ?? 96,
          decoration: const InputDecoration(labelText: 'PL si es prefijo de red específico (RFC 6052)', border: OutlineInputBorder()),
          items: rfc6052AllowedPrefixLengths
              .map((p) => DropdownMenuItem(value: p, child: Text('/$p')))
              .toList(),
          onChanged: (v) => setState(() => prefixLenCtrl.text = '$v'),
        ),
      ),
    ];
  }
}
