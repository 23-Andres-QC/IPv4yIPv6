import 'package:flutter/material.dart';
import '../app_localization.dart';
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

  String _translatedMessage(String message) {
    final ipv4Mapped = 'IPv4-mapped detectado';
    if (message == ipv4Mapped) {
      return context.t(ipv4Mapped);
    }
    final nat64 = 'RFC 6052 / NAT64 WKP /96 detectado';
    if (message == nat64) {
      return context.t(nat64);
    }
    final localNat64 = 'RFC 6052 / prefijo local 64:ff9b:1::/48 detectado';
    if (message == localNat64) {
      return context.t(localNat64);
    }
    final sixToFour = '6to4 detectado';
    if (message == sixToFour) {
      return context.t(sixToFour);
    }
    final sixToFourWarning =
        'Advertencia: la dirección parece 6to4, pero no se pudo extraer una IPv4.';
    if (message == sixToFourWarning) {
      return context.t(sixToFourWarning);
    }
    if (message.startsWith('Advertencia RFC 6052 §3.1:')) {
      return context.t(
        'Advertencia RFC 6052 §3.1: el Well-Known Prefix 64:ff9b::/96 NO debe usarse con direcciones IPv4 no globales (ej. RFC 1918). Esos paquetes deberían descartarse. Si necesitas representar una IPv4 privada, usa el prefijo local 64:ff9b:1::/48 (RFC 8215) o un Network-Specific Prefix propio.',
      );
    }
    if (message.startsWith(
      'Aviso: el prefijo IPv6 ingresado contiene bits fuera de /',
    )) {
      if (!context.isEnglish) return message;
      final match = RegExp(
        r'fuera de /(\d+); se usará ([^ ]+)\.',
      ).firstMatch(message);
      if (match != null) {
        return 'Notice: the entered IPv6 prefix contains bits outside /${match.group(1)}; ${match.group(2)} will be used.';
      }
    }
    if (message.startsWith(
      'Advertencia: 6to4 requiere una IPv4 pública única;',
    )) {
      if (!context.isEnglish) return message;
      final match = RegExp(
        r'única; ([^ ]+) está clasificada como (.+)\.',
      ).firstMatch(message);
      if (match != null) {
        return 'Warning: 6to4 requires a unique public IPv4 address; ${match.group(1)} is classified as ${context.t(match.group(2)!)}.';
      }
    }
    return context.t(message);
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
            throw TransitionException('La dirección IPv6 no contiene IPv4.');
          }
        }
      } on Ipv4FormatException {
        error = 'Dirección IPv4 no válida';
      } on Ipv6FormatException {
        error = 'Dirección IPv6 no válida';
      } on TransitionException catch (e) {
        error = e.message;
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
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('Transición IPv4 ↔ IPv6'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                context.t(
                  'IPv4-mapped (RFC 4291), incrustación RFC 6052 (NAT64/SIIT) y 6to4 (RFC 3056).',
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<_Direction>(
                segments: [
                  ButtonSegment(
                    value: _Direction.v4ToV6,
                    label: Text(context.t('IPv4 → IPv6')),
                  ),
                  ButtonSegment(
                    value: _Direction.v6ToV4,
                    label: Text(context.t('IPv6 → IPv4')),
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
              FilledButton(
                onPressed: _run,
                child: Text(context.t('Transformar')),
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
                        Text(
                          context.t('Revisa los datos de transición'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_translatedMessage(error!)),
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
                            '${context.t('Método')}: ${_translatedMessage(methodText!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (methodText != null) const SizedBox(height: 8),
                        for (final output in outputs) ...[
                          _buildOutputRow(output),
                          for (final warning in output.warnings)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 170),
                              child: Text(_translatedMessage(warning)),
                            ),
                          if (output != outputs.last) const Divider(),
                        ],
                        if (warnings.isNotEmpty) const Divider(),
                        if (warnings.isNotEmpty)
                          Text(
                            context.t('Advertencias'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        for (final n in warnings)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_translatedMessage(n)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildV4ToV6Inputs() {
    return [
      SizedBox(
        width: 360,
        child: TextField(
          controller: ipv4Ctrl,
          decoration: InputDecoration(
            labelText: context.t('Dirección IPv4'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _clearResult(),
          onSubmitted: (_) => _run(),
        ),
      ),
      const SizedBox(height: 12),
      Text(context.t('Se mostrarán IPv4-mapped, RFC 6052/NAT64 WKP y 6to4.')),
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
        width: 520,
        child: TextField(
          controller: ipv6Ctrl,
          decoration: InputDecoration(
            labelText: context.t('Dirección IPv6'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _clearResult(),
          onSubmitted: (_) => _run(),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.t(
          'Detecta automáticamente IPv4-mapped, NAT64 WKP/local y 6to4.',
        ),
      ),
    ];
  }
}
