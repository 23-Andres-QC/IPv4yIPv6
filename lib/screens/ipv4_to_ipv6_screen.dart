import 'package:flutter/material.dart';
import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../core/transition.dart';

enum _Direction { v4ToV6, v6ToV4 }

class _TransitionOutput {
  final String title;
  final String value;
  final List<String> warnings;
  const _TransitionOutput(this.title, this.value, {this.warnings = const []});
}

class Ipv4ToIpv6Screen extends StatefulWidget {
  const Ipv4ToIpv6Screen({super.key});
  @override
  State<Ipv4ToIpv6Screen> createState() => _Ipv4ToIpv6ScreenState();
}

class _Ipv4ToIpv6ScreenState extends State<Ipv4ToIpv6Screen> {
  _Direction direction = _Direction.v4ToV6;

  final ipv4Ctrl = TextEditingController(text: '8.8.8.8');
  final ipv6Ctrl = TextEditingController(text: '64:ff9b::8.8.8.8');

  String? error;
  String? methodText;
  List<_TransitionOutput> outputs = [];
  List<String> warnings = [];

  @override
  void dispose() {
    ipv4Ctrl.dispose();
    ipv6Ctrl.dispose();
    super.dispose();
  }

  void _clearResult() {
    if (error == null &&
        methodText == null &&
        outputs.isEmpty &&
        warnings.isEmpty) {
      return;
    }
    setState(() {
      error = null;
      methodText = null;
      outputs = [];
      warnings = [];
    });
  }

  List<String> _visibleWarnings(List<String> notes) {
    return notes
        .where(
          (note) => note.startsWith('Advertencia') || note.startsWith('Aviso'),
        )
        .toList();
  }

  String _primaryAddress(String text) {
    return text.split('  (mixta:').first.trim();
  }

  void _run() {
    setState(() {
      error = null;
      methodText = null;
      outputs = [];
      warnings = [];
      try {
        if (direction == _Direction.v4ToV6) {
          final ipv4 = Ipv4Address.parse(ipv4Ctrl.text);
          final mapped = TransitionEngine.ipv4ToMapped(ipv4);
          final rfc6052 = TransitionEngine.embedRfc6052(
            ipv4,
            Ipv6Address.parse('64:ff9b::'),
            96,
          );
          final sixToFour = TransitionEngine.ipv4ToSixToFour(ipv4);
          outputs = [
            _TransitionOutput(
              'IPv4-mapped',
              mapped.resultText,
              warnings: _visibleWarnings(mapped.notes),
            ),
            _TransitionOutput(
              'NAT64 (RFC 6052)',
              _primaryAddress(rfc6052.resultText),
              warnings: _visibleWarnings(rfc6052.notes),
            ),
            _TransitionOutput(
              '6to4',
              sixToFour.resultText,
              warnings: _visibleWarnings(sixToFour.notes),
            ),
          ];
        } else {
          final v6 = Ipv6Address.parse(ipv6Ctrl.text);
          final cls = v6.classification;
          if (cls == Ipv6Class.ipv4Mapped) {
            final v4 = TransitionEngine.mappedToIpv4(v6)!;
            methodText = 'IPv4-mapped detectado';
            outputs = [_TransitionOutput('IPv4', v4.dotted)];
          } else if (cls == Ipv6Class.nat64WellKnown) {
            final v4 = TransitionEngine.extractRfc6052(v6, 96);
            methodText = 'RFC 6052 / NAT64 WKP /96 detectado';
            outputs = [_TransitionOutput('IPv4', v4.dotted)];
          } else if (cls == Ipv6Class.nat64Local) {
            final v4 = TransitionEngine.extractRfc6052(v6, 48);
            methodText = 'RFC 6052 / prefijo local 64:ff9b:1::/48 detectado';
            outputs = [_TransitionOutput('IPv4', v4.dotted)];
          } else if (cls == Ipv6Class.sixToFour) {
            final v4 = TransitionEngine.sixToFourToIpv4(v6);
            if (v4 == null) {
              warnings.add(
                'Advertencia: la dirección parece 6to4, pero no se pudo extraer una IPv4.',
              );
            } else {
              methodText = '6to4 detectado';
              outputs = [_TransitionOutput('IPv4', v4.dotted)];
            }
          } else {
            throw TransitionException(
              'No se detectó un formato convertible automáticamente. Usa IPv4-mapped, NAT64 64:ff9b::/96, NAT64 local 64:ff9b:1::/48 o 6to4.',
            );
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
          Text(
            'Transición IPv4 ↔ IPv6',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'IPv4-mapped (RFC 4291), incrustación RFC 6052 (NAT64/SIIT) y 6to4 (RFC 3056).',
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Direction>(
            segments: const [
              ButtonSegment(
                value: _Direction.v4ToV6,
                label: Text('IPv4 → IPv6'),
              ),
              ButtonSegment(
                value: _Direction.v6ToV4,
                label: Text('IPv6 → IPv4'),
              ),
            ],
            selected: {direction},
            onSelectionChanged: (s) {
              setState(() {
                direction = s.first;
                error = null;
                methodText = null;
                outputs = [];
                warnings = [];
              });
            },
          ),
          const SizedBox(height: 16),
          if (direction == _Direction.v4ToV6)
            ..._buildV4ToV6Inputs()
          else
            ..._buildV6ToV4Inputs(),
          const SizedBox(height: 16),
          FilledButton(onPressed: _run, child: const Text('Transformar')),
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
                      'Revisa los datos de transición',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(error!),
                  ],
                ),
              ),
            ),
          if (outputs.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (methodText != null)
                      Text(
                        'Método: $methodText',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (methodText != null) const SizedBox(height: 8),
                    for (final output in outputs) ...[
                      _buildOutputRow(output),
                      for (final warning in output.warnings)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 170),
                          child: Text(warning),
                        ),
                      if (output != outputs.last) const Divider(),
                    ],
                    if (warnings.isNotEmpty) const Divider(),
                    if (warnings.isNotEmpty)
                      const Text(
                        'Advertencias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    for (final n in warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(n),
                      ),
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
      SizedBox(
        width: 360,
        child: TextField(
          controller: ipv4Ctrl,
          decoration: const InputDecoration(
            labelText: 'Dirección IPv4',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _clearResult(),
          onSubmitted: (_) => _run(),
        ),
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
                value: int.tryParse(prefixLenCtrl.text) ?? 96,
                decoration: const InputDecoration(labelText: 'PL', border: OutlineInputBorder()),
                items: rfc6052AllowedPrefixLengths
                    .map((p) => DropdownMenuItem(value: p, child: Text('/$p')))
                    .toList(),
                onChanged: (v) => setState(() => prefixLenCtrl.text = '$v'),
              ),
      const Text('Se mostrarán IPv4-mapped, RFC 6052/NAT64 WKP y 6to4.'),
    ];
  }

  Widget _buildOutputRow(_TransitionOutput output) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            '${output.title}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(
            output.value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildV6ToV4Inputs() {
    return [
      SizedBox(
        width: 200,
        child: DropdownButtonFormField<int>(
          value: int.tryParse(prefixLenCtrl.text) ?? 96,
          decoration: const InputDecoration(labelText: 'PL si es prefijo de red específico (RFC 6052)', border: OutlineInputBorder()),
          items: rfc6052AllowedPrefixLengths
              .map((p) => DropdownMenuItem(value: p, child: Text('/$p')))
              .toList(),
          onChanged: (v) => setState(() => prefixLenCtrl.text = '$v'),
        width: 520,
        child: TextField(
          controller: ipv6Ctrl,
          decoration: const InputDecoration(
            labelText: 'Dirección IPv6',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _clearResult(),
          onSubmitted: (_) => _run(),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Detecta automáticamente IPv4-mapped, NAT64 WKP/local y 6to4.',
      ),
    ];
  }
}
