import 'dart:async';
// ignore_for_file: deprecated_member_use, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_localization.dart';
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
  Timer? _debounce;

  Ipv4Prefix? v4result;
  Ipv6Prefix? v6result;

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _calculate);
  }

  void _calculate() {
    setState(() {
      error = null;
      v4result = null;
      v6result = null;
      final prefixLen = int.tryParse(prefixCtrl.text.trim());
      if (prefixLen == null) {
        error = isIpv6
            ? 'El prefijo debe ser un número entre 0 y 128. Ej: 64'
            : 'El prefijo debe ser un número entre 0 y 32. Ej: 24';
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
        error = _friendlyError(e.toString());
      }
    });
  }

  String _friendlyError(String raw) {
    if (raw.contains('octeto') || raw.contains('no tiene 4')) {
      return 'Dirección inválida. Usa el formato correcto: 192.168.0.1';
    }
    if (raw.contains('prefijo') || raw.contains('longitud')) {
      return isIpv6
          ? 'El prefijo debe ser un número entre 0 y 128.'
          : 'El prefijo debe ser un número entre 0 y 32.';
    }
    if (raw.contains('grupos') || raw.contains('hexadecimal')) {
      return 'Dirección IPv6 inválida. Usa el formato: 2001:db8::1';
    }
    return raw;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('Copiado: $text'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 320,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _calculate();
    addressCtrl.addListener(_onChanged);
    prefixCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    addressCtrl.dispose();
    prefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildInputCard(context),
          const SizedBox(height: 16),
          if (error != null) _buildErrorCard(context, error!),
          if (v4result != null) _buildIpv4Result(v4result!),
          if (v6result != null) _buildIpv6Result(v6result!),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('Calculadora de direcciones'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                context.t(
                  'Ingresa una dirección IP y un prefijo para analizar la subred completa.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Input card ────────────────────────────────────────────────────────────

  Widget _buildInputCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('Versión del protocolo'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('IPv4'),
                  icon: Icon(Icons.looks_4_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('IPv6'),
                  icon: Icon(Icons.looks_6_outlined),
                ),
              ],
              selected: {isIpv6},
              onSelectionChanged: (s) {
                setState(() {
                  isIpv6 = s.first;
                  addressCtrl.text = isIpv6
                      ? '2001:db8:1200:12ab::'
                      : '192.168.0.1';
                  prefixCtrl.text = isIpv6 ? '64' : '24';
                });
                _calculate();
              },
            ),
            const SizedBox(height: 20),
            Text(
              context.t('Dirección y prefijo de red'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: context.t('Dirección IP'),
                      hintText: isIpv6 ? 'Ej: 2001:db8::1' : 'Ej: 192.168.0.1',
                      helperText: isIpv6
                          ? context.t(
                              'Grupos hexadecimales separados por dos puntos',
                            )
                          : context.t(
                              'Cuatro números del 0 al 255, separados por puntos',
                            ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.router_outlined),
                    ),
                    onSubmitted: (_) => _calculate(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
                  child: Tooltip(
                    message:
                        'Separador CIDR: divide la dirección del prefijo de red',
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: prefixCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.t('Prefijo'),
                      hintText: isIpv6 ? '0–128' : '0–32',
                      helperText: context.t('Bits de red'),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FilledButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(context.t('Calcular')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error card ────────────────────────────────────────────────────────────

  Widget _buildErrorCard(BuildContext context, String msg) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Dirección inválida'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── IPv4 result ───────────────────────────────────────────────────────────

  Widget _buildIpv4Result(Ipv4Prefix p) {
    final colorScheme = Theme.of(context).colorScheme;
    final cls = p.address.classification;
    final clsColor = _classColor(cls, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detail table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _sectionTitle(
                        context,
                        Icons.table_rows_rounded,
                        'Detalles de la subred',
                      ),
                    ),
                    IconButton(
                      icon: Icon(_classIcon(cls), color: clsColor),
                      tooltip: 'Ver tipo de red',
                      onPressed: () => _showNetworkTypeDialog(context, cls),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow(
                  context,
                  'Red',
                  'Identificador del bloque de red',
                  '${p.network.dotted}/${p.length}',
                  Colors.indigo.shade600,
                ),
                _divider(),
                if (p.firstUsable != null)
                  _detailRow(
                    context,
                    'Primer host',
                    'Primera IP asignable a un dispositivo',
                    p.firstUsable!.dotted,
                    Colors.green.shade700,
                  ),
                if (p.lastUsable != null) ...[
                  _divider(),
                  _detailRow(
                    context,
                    'Último host',
                    'Última IP asignable a un dispositivo',
                    p.lastUsable!.dotted,
                    Colors.green.shade700,
                  ),
                ],
                _divider(),
                _detailRow(
                  context,
                  'Broadcast',
                  'Envío simultáneo a todos los dispositivos',
                  p.broadcastAddress.dotted,
                  Colors.orange.shade700,
                ),
                _divider(),
                _detailRow(
                  context,
                  'Máscara de subred',
                  'Distingue la parte de red de la de host',
                  '${p.mask.dotted}  =  /${p.length}',
                  colorScheme.onSurface,
                ),
                _divider(),
                _detailRow(
                  context,
                  'Wildcard',
                  'Inverso de la máscara, usado en ACLs y firewalls',
                  p.wildcard.dotted,
                  colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 20),
                _buildStatsRow(
                  context,
                  p.totalAddresses.toString(),
                  _formatNumber(p.usableHostCount),
                ),
                if (p.length == 31)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _infoBanner(
                      context,
                      'RFC 3021: en prefijos /31, ambas IPs son utilizables como host (enlace punto a punto).',
                    ),
                  ),
                if (p.length == 32)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _infoBanner(
                      context,
                      'Host route /32: representa un único dispositivo específico, sin subred.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Binary (collapsible)
        _buildBinaryCard(
          context,
          children: [
            _buildBinaryLegend(context, includeRed: true),
            const SizedBox(height: 12),
            BitRow(
              label: 'Dirección',
              sublabel: p.address.dotted,
              spans: ipv4BitSpans(
                p.address.value,
                p.length,
                prefixColor: Colors.blue,
              ),
              trailing: p.address.dotted,
            ),
            BitRow(
              label: 'Máscara',
              sublabel: '/${p.length}',
              spans: ipv4BitSpans(
                p.mask.value,
                p.length,
                prefixColor: Colors.red,
              ),
              trailing: '${p.mask.dotted} = /${p.length}',
            ),
            BitRow(
              label: 'Wildcard',
              sublabel: 'Inverso máscara',
              spans: ipv4BitSpans(
                p.wildcard.value,
                0,
                prefixColor: Colors.red,
                hostColor: Colors.black54,
              ),
              trailing: p.wildcard.dotted,
            ),
            _divider(),
            BitRow(
              label: 'Red',
              sublabel: 'Subred',
              spans: ipv4BitSpans(
                p.network.value,
                p.length,
                prefixColor: Colors.green,
              ),
              trailing: '${p.network.dotted}/${p.length}',
            ),
            if (p.firstUsable != null)
              BitRow(
                label: 'Primer host',
                sublabel: 'HostMin',
                spans: ipv4BitSpans(
                  p.firstUsable!.value,
                  p.length,
                  prefixColor: Colors.green,
                ),
                trailing: p.firstUsable!.dotted,
              ),
            if (p.lastUsable != null)
              BitRow(
                label: 'Último host',
                sublabel: 'HostMax',
                spans: ipv4BitSpans(
                  p.lastUsable!.value,
                  p.length,
                  prefixColor: Colors.green,
                ),
                trailing: p.lastUsable!.dotted,
              ),
            BitRow(
              label: 'Broadcast',
              sublabel: 'Difusión',
              spans: ipv4BitSpans(
                p.broadcastAddress.value,
                p.length,
                prefixColor: Colors.green,
              ),
              trailing: p.broadcastAddress.dotted,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── IPv6 result ───────────────────────────────────────────────────────────

  Widget _buildIpv6Result(Ipv6Prefix p) {
    final colorScheme = Theme.of(context).colorScheme;
    final cls = p.address.classification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _sectionTitle(
                        context,
                        Icons.table_rows_rounded,
                        'Formas de la dirección',
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.language_rounded,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Ver tipo de red',
                      onPressed: () => _showIpv6TypeDialog(context, cls),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow(
                  context,
                  'Canónica',
                  'Forma comprimida según RFC 5952',
                  p.address.canonical,
                  colorScheme.primary,
                ),
                _divider(),
                _detailRow(
                  context,
                  'Forma completa',
                  'Los 128 bits sin comprimir',
                  p.address.fullForm,
                  colorScheme.onSurface,
                ),
                if (cls == Ipv6Class.ipv4Mapped ||
                    cls == Ipv6Class.nat64WellKnown) ...[
                  _divider(),
                  _detailRow(
                    context,
                    'Forma mixta',
                    'IPv6 con IPv4 embebida',
                    p.address.mixedFormIfApplicable,
                    colorScheme.secondary,
                  ),
                ],
                _divider(),
                _detailRow(
                  context,
                  'Inicio del prefijo',
                  'Primera dirección del bloque /${p.length}',
                  p.networkStart.canonical,
                  Colors.green.shade700,
                ),
                _divider(),
                _detailRow(
                  context,
                  'Fin del prefijo',
                  'Última dirección del bloque /${p.length}',
                  p.networkEnd.canonical,
                  Colors.green.shade700,
                ),
                const SizedBox(height: 16),
                _infoBanner(
                  context,
                  'IPv6 no usa broadcast. La difusión grupal se realiza con multicast (RFC 4291) y Neighbor Discovery (RFC 4861).',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _buildBinaryCard(
          context,
          children: [
            _buildBinaryLegend(context, includeRed: true),
            const SizedBox(height: 12),
            BitRow(
              label: 'Dirección',
              sublabel: p.address.canonical,
              spans: ipv6BitSpans(
                p.address.value,
                p.length,
                prefixColor: Colors.blue,
              ),
            ),
            BitRow(
              label: 'Máscara',
              sublabel: '/${p.length}',
              spans: ipv6BitSpans(
                p.mask.value,
                p.length,
                prefixColor: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _buildClassificationBanner(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_SummaryItem> items,
    required Color accent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: accent.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              context,
              Icons.dashboard_rounded,
              title,
              color: accent,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((item) {
                return InkWell(
                  onTap: () => _copyToClipboard(item.value),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accent,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String sublabel,
    String value,
    Color valueColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(label),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  context.t(sublabel),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: context.t('Copiar valor'),
            onPressed: () => _copyToClipboard(value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, String total, String usable) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCell(
            context,
            Icons.numbers_rounded,
            'Direcciones totales',
            total,
          ),
          Container(width: 1, height: 56, color: colorScheme.outlineVariant),
          _statCell(
            context,
            Icons.devices_rounded,
            'Hosts utilizables',
            usable,
          ),
        ],
      ),
    );
  }

  Widget _statCell(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          context.t(label),
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBinaryCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.developer_mode_rounded,
            color: colorScheme.secondary,
          ),
          title: Text(
            context.t('Representación binaria'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            context.t(
              'Ver cada bit de la dirección — para estudiantes y profesionales',
            ),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildBinaryLegend(BuildContext context, {bool includeRed = false}) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _legendDot(context, Colors.blue, 'Bits de red (prefijo)'),
        _legendDot(context, Colors.grey, 'Bits de host'),
        if (includeRed) _legendDot(context, Colors.red, 'Bits de máscara'),
        _legendDot(context, Colors.green, 'Rango de subred'),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(context.t(label), style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _infoBanner(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(
          context.t(label),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: c),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5);

  // ─── Network type dialogs ──────────────────────────────────────────────────

  void _showNetworkTypeDialog(BuildContext context, Ipv4Class cls) {
    final isPublic = cls == Ipv4Class.global;
    final isPrivate = cls == Ipv4Class.private;
    final icon = isPublic ? Icons.public_rounded : Icons.home_rounded;
    final color = isPublic ? Colors.green.shade700 : Colors.blue.shade700;
    final label = isPublic
        ? 'Red Pública'
        : isPrivate
        ? 'Red Privada'
        : cls.label.split('(').first.trim();
    final desc = isPublic
        ? 'Esta dirección es accesible desde Internet.'
        : isPrivate
        ? 'Esta dirección pertenece a una red local. No es accesible desde Internet.'
        : _classDescription(cls);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: color, size: 36),
        title: Text(
          context.t(label),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Text(context.t(desc), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Entendido')),
          ),
        ],
      ),
    );
  }

  void _showIpv6TypeDialog(BuildContext context, Ipv6Class cls) {
    final isPublic = cls == Ipv6Class.globalUnicast;
    final isPrivate = cls == Ipv6Class.uniqueLocal;
    final icon = isPublic ? Icons.public_rounded : Icons.home_rounded;
    final color = isPublic ? Colors.green.shade700 : Colors.blue.shade700;
    final label = isPublic
        ? 'Red Pública'
        : isPrivate
        ? 'Red Privada'
        : cls.label.split('(').first.trim();
    final desc = isPublic
        ? 'Esta dirección IPv6 es accesible desde Internet.'
        : isPrivate
        ? 'Esta dirección IPv6 pertenece a una red local (ULA). No es accesible desde Internet.'
        : cls.label;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: color, size: 36),
        title: Text(
          context.t(label),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Text(context.t(desc), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Entendido')),
          ),
        ],
      ),
    );
  }

  // ─── Classification helpers ────────────────────────────────────────────────

  Color _classColor(Ipv4Class cls, ColorScheme cs) {
    switch (cls) {
      case Ipv4Class.private:
        return Colors.blue.shade700;
      case Ipv4Class.global:
        return Colors.green.shade700;
      case Ipv4Class.loopback:
        return Colors.purple.shade700;
      case Ipv4Class.multicast:
        return Colors.orange.shade700;
      case Ipv4Class.linkLocal:
        return Colors.teal.shade700;
      case Ipv4Class.documentation:
        return Colors.grey.shade600;
      case Ipv4Class.broadcastLimited:
        return Colors.red.shade700;
      default:
        return cs.primary;
    }
  }

  IconData _classIcon(Ipv4Class cls) {
    switch (cls) {
      case Ipv4Class.private:
        return Icons.home_outlined;
      case Ipv4Class.global:
        return Icons.public_outlined;
      case Ipv4Class.loopback:
        return Icons.loop_rounded;
      case Ipv4Class.multicast:
        return Icons.cell_tower_outlined;
      case Ipv4Class.linkLocal:
        return Icons.link_rounded;
      case Ipv4Class.documentation:
        return Icons.description_outlined;
      case Ipv4Class.broadcastLimited:
        return Icons.broadcast_on_home_outlined;
      default:
        return Icons.label_outline;
    }
  }

  String _classDescription(Ipv4Class cls) {
    switch (cls) {
      case Ipv4Class.private:
        return 'Uso en redes locales (hogares, oficinas). No enrutable en Internet.';
      case Ipv4Class.global:
        return 'Dirección pública. Puede ser alcanzada desde cualquier punto de Internet.';
      case Ipv4Class.loopback:
        return 'Dirección de prueba interna. El tráfico nunca abandona el dispositivo.';
      case Ipv4Class.multicast:
        return 'Envío simultáneo a múltiples receptores suscritos a un grupo.';
      case Ipv4Class.linkLocal:
        return 'Asignada automáticamente (APIPA) cuando no hay servidor DHCP disponible.';
      case Ipv4Class.documentation:
        return 'Reservada solo para ejemplos y documentación técnica. No usar en producción.';
      case Ipv4Class.sharedCgnat:
        return 'Usada por proveedores de Internet en redes CGN/LSN (Carrier-Grade NAT).';
      case Ipv4Class.benchmarking:
        return 'Reservada para pruebas de rendimiento de red (RFC 2544).';
      case Ipv4Class.broadcastLimited:
        return 'Envía a todos los dispositivos de la red local sin conocer la subred.';
      case Ipv4Class.reserved:
        return 'Reservada para uso experimental futuro. No debe asignarse.';
      default:
        return '';
    }
  }

  String _ipv6ClassDescription(Ipv6Class cls) {
    switch (cls) {
      case Ipv6Class.uniqueLocal:
        return 'Equivalente IPv6 de las IPs privadas. Solo válida dentro de una organización.';
      case Ipv6Class.globalUnicast:
        return 'Dirección pública IPv6. Enrutable en Internet.';
      case Ipv6Class.linkLocal:
        return 'Solo válida en el mismo segmento de red. No se puede rutear.';
      case Ipv6Class.multicast:
        return 'Envío grupal. No existe broadcast en IPv6.';
      case Ipv6Class.loopback:
        return 'Dirección interna del dispositivo. Equivale a 127.0.0.1 en IPv4.';
      case Ipv6Class.documentation:
        return 'Reservada para ejemplos y documentación técnica.';
      case Ipv6Class.ipv4Mapped:
        return 'Representación IPv6 de una dirección IPv4. Solo uso interno.';
      default:
        return '';
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _SummaryItem {
  final String label;
  final String value;
  const _SummaryItem(this.label, this.value);
}
