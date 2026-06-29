// ignore_for_file: deprecated_member_use, unused_element, unused_element_parameter, unused_local_variable

import 'package:flutter/material.dart';
import '../app_localization.dart';
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
  final addressCtrl = TextEditingController();
  final prefixCtrl = TextEditingController();
  bool dualStack = false;
  bool hasTranslator = false;

  void dispose() {
    addressCtrl.dispose();
    prefixCtrl.dispose();
  }
}

class _Preset {
  final String label;
  final String description;
  final bool aIsIpv6;
  final String aAddress;
  final String aPrefix;
  final bool aDual;
  final bool aTrans;
  final bool bIsIpv6;
  final String bAddress;
  final String bPrefix;
  final bool bDual;
  final bool bTrans;

  const _Preset({
    required this.label,
    required this.description,
    this.aIsIpv6 = false,
    required this.aAddress,
    required this.aPrefix,
    this.aDual = false,
    this.aTrans = false,
    this.bIsIpv6 = false,
    required this.bAddress,
    required this.bPrefix,
    this.bDual = false,
    this.bTrans = false,
  });
}

const _presets = [
  _Preset(
    label: 'Misma red',
    description: 'Ambos en la misma subred — sin router',
    aAddress: '192.168.1.10',
    aPrefix: '24',
    bAddress: '192.168.1.50',
    bPrefix: '24',
  ),
  _Preset(
    label: 'Redes distintas',
    description: 'Necesitan un router en el medio',
    aAddress: '192.168.0.10',
    aPrefix: '24',
    bAddress: '10.0.0.5',
    bPrefix: '8',
  ),
  _Preset(
    label: 'Sin camino',
    description: 'IPv4 vs IPv6 sin ninguna solución',
    aAddress: '192.168.1.1',
    aPrefix: '24',
    bIsIpv6: true,
    bAddress: '2001:db8::1',
    bPrefix: '64',
  ),
  _Preset(
    label: 'Con traductor',
    description: 'IPv4 vs IPv6 usando NAT64',
    aAddress: '192.168.1.1',
    aPrefix: '24',
    aTrans: true,
    bIsIpv6: true,
    bAddress: '2001:db8::1',
    bPrefix: '64',
  ),
  _Preset(
    label: 'Dual-stack',
    description: 'Ambos hablan IPv4 e IPv6',
    aAddress: '192.168.1.1',
    aPrefix: '24',
    aDual: true,
    bIsIpv6: true,
    bAddress: '2001:db8::1',
    bPrefix: '64',
    bDual: true,
  ),
];

// ── Helpers ────────────────────────────────────────────────────────────────

String _formatCount(int n) {
  final s = n.toString();
  final reversed = s.split('').reversed.toList();
  final parts = <String>[];
  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) parts.add(',');
    parts.add(reversed[i]);
  }
  return parts.reversed.join();
}

({String mask, String hostLine, String? warning, bool isValid}) _prefixData(
  String text,
  bool isIpv6,
) {
  final maxLen = isIpv6 ? 128 : 32;
  final len = int.tryParse(text.trim());

  if (len == null) {
    return (
      mask: '',
      hostLine: '',
      warning: 'Ingresa un número válido.',
      isValid: false,
    );
  }
  if (len < 0 || len > maxLen) {
    return (
      mask: '',
      hostLine: '',
      warning: 'El prefijo debe estar entre 0 y $maxLen.',
      isValid: false,
    );
  }

  if (isIpv6) {
    final exp = 128 - len;
    final String hostLine;
    final String? warning;
    if (exp == 0) {
      hostLine = '1 dirección  (2⁰)';
      warning = '/128 — identifica un único dispositivo. No es una red.';
    } else if (exp == 1) {
      hostLine = '2 direcciones  (2¹)';
      warning =
          '/127 — enlace punto a punto entre dos dispositivos (RFC 6164).';
    } else {
      hostLine = '2^$exp direcciones en esta red';
      warning = null;
    }
    return (mask: '', hostLine: hostLine, warning: warning, isValid: true);
  }

  // IPv4 ──────────────────────────────────────────────────────────────────
  final shift = 32 - len;
  final maskVal = shift >= 32 ? 0 : ((0xFFFFFFFF << shift) & 0xFFFFFFFF);
  final mask =
      '${(maskVal >> 24) & 0xFF}.${(maskVal >> 16) & 0xFF}.${(maskVal >> 8) & 0xFF}.${maskVal & 0xFF}';

  final String hostLine;
  final String? warning;

  if (len == 32) {
    hostLine = '1 dirección  (2⁰)';
    warning =
        '/32 — host único. No es una red, identifica un solo dispositivo.';
  } else if (len == 31) {
    hostLine = '2 hosts  (2¹)';
    warning =
        '/31 — enlace punto a punto. Ambas IPs son utilizables (RFC 3021).';
  } else if (len == 0) {
    hostLine = '4,294,967,294 hosts  (2³² − 2)';
    warning =
        '/0 — representa toda la red IPv4. No usar como prefijo de subred.';
  } else {
    final total = 1 << shift;
    final hosts = total - 2;
    final exp = shift;
    hostLine = '${_formatCount(hosts)} hosts disponibles  (2^$exp − 2)';
    warning = null;
  }

  return (mask: mask, hostLine: hostLine, warning: warning, isValid: true);
}

// ── Screen ─────────────────────────────────────────────────────────────────

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final a = _EndpointInput()
    ..addressCtrl.text = '192.168.0.10'
    ..prefixCtrl.text = '24';
  final b = _EndpointInput()
    ..addressCtrl.text = '203.0.113.5'
    ..prefixCtrl.text = '28';

  ConnectivityResult? result;
  String? error;
  bool _showDetails = false;
  bool _showExamples = false;

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
      _showDetails = false;
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

  void _applyPreset(_Preset p) {
    setState(() {
      a.isIpv6 = p.aIsIpv6;
      a.addressCtrl.text = p.aAddress;
      a.prefixCtrl.text = p.aPrefix;
      a.dualStack = p.aDual;
      a.hasTranslator = p.aTrans;
      b.isIpv6 = p.bIsIpv6;
      b.addressCtrl.text = p.bAddress;
      b.prefixCtrl.text = p.bPrefix;
      b.dualStack = p.bDual;
      b.hasTranslator = p.bTrans;
    });
    _evaluate();
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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Conectividad entre dispositivos'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'Ingresa dos direcciones IP y te diremos cómo pueden comunicarse entre sí.',
            ),
          ),
          const SizedBox(height: 20),

          // ── Ejemplos rápidos (colapsable) ────────────────────────────
          OutlinedButton.icon(
            onPressed: () => setState(() => _showExamples = !_showExamples),
            icon: Icon(
              _showExamples ? Icons.expand_less : Icons.bolt,
              size: 16,
            ),
            label: Text(
              _showExamples
                  ? context.t('Ocultar ejemplos')
                  : context.t('Ver ejemplos de prueba'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          if (_showExamples) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.4,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(
                      'Selecciona un caso para cargarlo automáticamente:',
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final p in _presets) _exampleCard(p, theme),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Cards dispositivos ────────────────────────────────────────
          Text(
            context.t('Conectividad entre dos extremos'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'Distingue mismo enlace, ruteo entre subredes, dual-stack declarado y traducción/túnel declarado.',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _endpointCard(
                  context.t('Dispositivo origen'),
                  context.t('El que inicia la comunicación'),
                  a,
                  Icons.computer,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 55),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _endpointCard(
                  context.t('Dispositivo destino'),
                  context.t('El que recibe la comunicación'),
                  b,
                  Icons.dns,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _evaluate,
              icon: const Icon(Icons.network_check),
              label: Text(context.t('Evaluar conectividad')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Revisa los datos de conectividad'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(error!),
                  ],
                ),
              ),
            ),
          if (result != null) ...[
            // Cabecera de resultado
            Row(
              children: [
                const Icon(
                  Icons.assessment_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  context.t('Resultado del análisis'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Leyenda de colores
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _legendChip(
                  Colors.green.shade600,
                  context.t('Comunicación directa'),
                ),
                _legendChip(Colors.blue.shade600, context.t('Necesita router')),
                _legendChip(
                  Colors.orange.shade600,
                  context.t('Necesita traductor'),
                ),
                _legendChip(
                  Colors.red.shade600,
                  context.t('Sin camino posible'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildResult(result!, theme),
          ],
        ],
      ),
    );
  }

  Widget _exampleCard(_Preset p, ThemeData theme) {
    final icons = {
      'Misma red': Icons.cable_rounded,
      'Redes distintas': Icons.router_rounded,
      'Sin camino': Icons.block_rounded,
      'Con traductor': Icons.translate_rounded,
      'Dual-stack': Icons.swap_horiz_rounded,
    };
    final colors = {
      'Misma red': Colors.green,
      'Redes distintas': Colors.blue,
      'Sin camino': Colors.red,
      'Con traductor': Colors.orange,
      'Dual-stack': Colors.green,
    };
    final icon = icons[p.label] ?? Icons.play_circle_outline;
    final color = colors[p.label] ?? theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        _applyPreset(p);
        setState(() => _showExamples = false);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t(p.label),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              context.t(p.description),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // ── Result card ─────────────────────────────────────────────────────────

  Widget _buildResult(ConnectivityResult r, ThemeData theme) {
    final (icon, accentColor, bgColor, summary) = _kindMeta(r.kind);
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.15),
                  radius: 22,
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.t(r.title),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.t(summary),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                context.t('Advertencias'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final warning in warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(warning),
                ),
            ],
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(
                _showDetails ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _showDetails
                    ? context.t('Ocultar detalles técnicos')
                    : context.t('Ver detalles técnicos'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (_showDetails) ...[
              const Divider(),
              for (final d in r.details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 15,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color, String) _kindMeta(ConnectivityKind k) {
    switch (k) {
      case ConnectivityKind.sameLinkDirect:
        return (
          Icons.cable_rounded,
          Colors.green.shade700,
          Colors.green.shade50,
          'Los dos dispositivos están en la misma red. Se comunican directamente sin necesitar ningún router ni intermediario.',
        );
      case ConnectivityKind.routedSameFamily:
        return (
          Icons.router_rounded,
          Colors.blue.shade700,
          Colors.blue.shade50,
          'Los dispositivos están en redes diferentes pero usan el mismo tipo de IP. Necesitan un router que lleve los datos de una red a la otra.',
        );
      case ConnectivityKind.dualStackCommonFamily:
        return (
          Icons.swap_horiz_rounded,
          Colors.green.shade700,
          Colors.green.shade50,
          'Uno usa IPv4 y el otro IPv6, pero ambos soportan los dos tipos a la vez. Pueden comunicarse usando la versión que tengan en común.',
        );
      case ConnectivityKind.translatedNat64:
      case ConnectivityKind.translatedSiit:
      case ConnectivityKind.translated6to4:
        return (
          Icons.translate_rounded,
          Colors.orange.shade700,
          Colors.amber.shade50,
          'Uno usa IPv4 y el otro IPv6. Pueden comunicarse, pero necesitan un dispositivo que traduzca entre los dos tipos de IP.',
        );
      case ConnectivityKind.noPath:
        return (
          Icons.block_rounded,
          Colors.red.shade700,
          Colors.red.shade50,
          'No hay forma de que se comuniquen. Uno usa IPv4 y el otro IPv6, y no hay ningún traductor ni dispositivo que soporte los dos tipos al mismo tiempo.',
        );
    }
  }

  // ── Endpoint card ────────────────────────────────────────────────────────

  Color _colorForKind(ConnectivityKind kind, BuildContext context) {
    return _kindMeta(kind).$3;
  }

  Widget _endpointCard(
    String title,
    String subtitle,
    _EndpointInput e,
    IconData cardIcon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            final maxLen = e.isIpv6 ? 128 : 32;
            final currentLen = int.tryParse(e.prefixCtrl.text.trim());
            final canInc = currentLen != null && currentLen < maxLen;
            final canDec = currentLen != null && currentLen > 0;
            final info = _prefixData(e.prefixCtrl.text, e.isIpv6);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      cardIcon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // IPv4 / IPv6 selector
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('IPv4'),
                        icon: Icon(Icons.looks_4_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('IPv6'),
                        icon: Icon(Icons.looks_6_outlined, size: 16),
                      ),
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
                ),
                const SizedBox(height: 10),

                // Dirección IP
                TextField(
                  controller: e.addressCtrl,
                  decoration: InputDecoration(
                    labelText: context.t('Dirección IP'),
                    hintText: e.isIpv6 ? 'Ej: 2001:db8::1' : 'Ej: 192.168.1.10',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                    ),
                  ),
                  onChanged: (_) => _clearResult(),
                  onSubmitted: (_) => _evaluate(),
                ),
                const SizedBox(height: 10),

                // ── Prefijo con botones +/- ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.prefixCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.t('Prefijo (tamaño de red)'),
                          hintText: e.isIpv6 ? 'Ej: 64' : 'Ej: 24',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lan_outlined, size: 18),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Stepper unificado
                    Container(
                      width: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stepHalf(
                            icon: Icons.keyboard_arrow_up_rounded,
                            enabled: canInc,
                            tooltip: canInc
                                ? context.t('Aumentar')
                                : '${context.t('Prefijo máximo')} (/$maxLen)',
                            onTap: () => setLocal(() {
                              e.prefixCtrl.text = '${currentLen! + 1}';
                            }),
                            isTop: true,
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                          _stepHalf(
                            icon: Icons.keyboard_arrow_down_rounded,
                            enabled: canDec,
                            tooltip: canDec
                                ? context.t('Reducir')
                                : '${context.t('Prefijo mínimo')} (/0)',
                            onTap: () => setLocal(() {
                              e.prefixCtrl.text = '${currentLen! - 1}';
                            }),
                            isTop: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Panel informativo del prefijo ────────────────────────
                const SizedBox(height: 8),
                _prefixInfoPanel(
                  info,
                  e.isIpv6,
                  maxLen,
                  currentLen,
                  (newVal) => setLocal(() {
                    e.prefixCtrl.text = '$newVal';
                    _clearResult();
                  }),
                ),

                const Divider(height: 20),

                // Capacidades
                Row(
                  children: [
                    Text(
                      context.t('Capacidades'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showCapacidadesDialog(context),
                          icon: const Icon(Icons.help_outline, size: 13),
                          label: Text(
                            context.t('¿Cuándo marcar?'),
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                CheckboxListTile(
                  value: e.dualStack,
                  subtitle: Text(
                    context.t('IPv4 + IPv6 simultáneo'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onChanged: (v) {
                    setLocal(() => e.dualStack = v ?? false);
                    _clearResult();
                  },
                  title: Text(context.t('Dual-stack declarado')),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),

                CheckboxListTile(
                  value: e.hasTranslator,
                  subtitle: const Text(
                    'NAT64 / SIIT / DS-Lite / MAP',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onChanged: (v) {
                    setLocal(() => e.hasTranslator = v ?? false);
                    _clearResult();
                  },
                  title: Text(context.t('Traducción/túnel declarado')),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCapacidadesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('¿Cuándo marcar cada opción?')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogSection(
                icon: Icons.layers_outlined,
                color: Colors.blue,
                title: context.t('Dual-stack'),
                description: context.t(
                  'Márcalo si el dispositivo tiene configuradas AMBAS versiones de IP al mismo tiempo.',
                ),
                siItems: [
                  context.t('Una PC o laptop moderna con IPv4 e IPv6 activos'),
                  context.t(
                    'Un servidor o router reciente con doble configuración',
                  ),
                ],
                noText: context.t(
                  'No lo marques si el dispositivo solo usa IPv4 o solo IPv6.',
                ),
              ),
              const Divider(height: 28),
              _dialogSection(
                icon: Icons.translate_outlined,
                color: Colors.orange,
                title: context.t(
                  'Con traductor (NAT64 / SIIT / DS-Lite / MAP)',
                ),
                description: context.t(
                  'Márcalo si en tu red hay un equipo especial que convierte tráfico de IPv4 a IPv6 o viceversa.',
                ),
                siItems: [
                  context.t(
                    'Una red empresarial o universitaria con gateway NAT64',
                  ),
                  context.t('Un proveedor de internet con DS-Lite'),
                ],
                noText: context.t(
                  'No lo marques si es una red doméstica normal. Es poco común.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Entendido')),
          ),
        ],
      ),
    );
  }

  Widget _dialogSection({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<String> siItems,
    required String noText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 13, height: 1.5)),
        const SizedBox(height: 10),
        // Cuándo SÍ
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('Márcalo cuando sea:'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            for (final item in siItems)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Cuándo NO
        Text(
          noText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.shade800,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _stepHalf({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
    required bool isTop,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(5) : Radius.zero,
          bottom: isTop ? Radius.zero : const Radius.circular(5),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 22,
          child: Icon(
            icon,
            size: 14,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _prefixInfoPanel(
    ({String mask, String hostLine, String? warning, bool isValid}) info,
    bool isIpv6,
    int maxLen,
    int? currentLen,
    void Function(int) onChanged,
  ) {
    if (!info.isValid || currentLen == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 15, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                info.warning ?? '',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final barColor = currentLen >= maxLen - 2
        ? Colors.orange.shade400
        : Colors.blue.shade400;

    return Row(
      children: [
        Text('/0', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                void updateFromDx(double dx) {
                  final fraction = (dx / constraints.maxWidth).clamp(0.0, 1.0);
                  onChanged((fraction * maxLen).round());
                }

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (d) => updateFromDx(d.localPosition.dx),
                    onPanUpdate: (d) => updateFromDx(d.localPosition.dx),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: currentLen / maxLen,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          '/$maxLen',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: Colors.blueGrey.shade400),
          const SizedBox(width: 5),
          Text(
            '$label ',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
