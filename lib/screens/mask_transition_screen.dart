import 'package:flutter/material.dart';

import '../core/ipv4.dart';
import '../core/ipv6.dart';
import '../core/subnetting.dart';
import '../widgets/bit_view.dart';

class _InputException implements Exception {
  final String message;
  _InputException(this.message);
  @override
  String toString() => message;
}

class MaskTransitionScreen extends StatefulWidget {
  const MaskTransitionScreen({super.key});
  @override
  State<MaskTransitionScreen> createState() => _MaskTransitionScreenState();
}

class _MaskTransitionScreenState extends State<MaskTransitionScreen> {
  bool isIpv6 = false;

  final addressCtrl = TextEditingController(text: '192.168.0.1');
  final originalPrefixCtrl = TextEditingController(text: '24');
  final newPrefixCtrl = TextEditingController();

  String? error;
  List<Ipv4SubnetRow>? v4rows;
  List<Ipv6Prefix>? v6rows;
  Ipv4Address? v4Input;
  Ipv4SubnetRow? v4Base;
  Ipv6Address? v6Input;
  Ipv6Prefix? v6Base;
  int originalLength = 24;
  int resolvedNewLength = 24;
  bool hasMaskTransition = false;

  bool get hasEffectiveMaskTransition =>
      hasMaskTransition && resolvedNewLength != originalLength;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  int _parseRequiredInt(String text, String fieldLabel) {
    final v = int.tryParse(text.trim());
    if (v == null) {
      throw _InputException('$fieldLabel debe ser un numero entero.');
    }
    return v;
  }

  void _calculate() {
    setState(() {
      error = null;
      v4rows = null;
      v6rows = null;
      v4Input = null;
      v4Base = null;
      v6Input = null;
      v6Base = null;
      hasMaskTransition = false;

      try {
        final p = _parseRequiredInt(
          originalPrefixCtrl.text,
          'La mascara original',
        );
        final targetText = newPrefixCtrl.text.trim();
        final q = targetText.isEmpty
            ? null
            : _parseRequiredInt(targetText, 'La mascara destino');
        originalLength = p;
        resolvedNewLength = q ?? p;
        hasMaskTransition = q != null;

        if (isIpv6) {
          final addr = Ipv6Address.parse(addressCtrl.text);
          v6Input = addr;
          v6Base = Ipv6Prefix(addr, p);
          if (q != null) {
            v6rows = Ipv6Subnetting.transitionMask(addr, p, q);
          }
        } else {
          final addr = Ipv4Address.parse(addressCtrl.text);
          v4Input = addr;
          v4Base = Ipv4SubnetRow(Ipv4Prefix(addr, p));
          if (q != null) {
            v4rows = Ipv4Subnetting.transitionMask(addr, p, q);
          }
        }
      } catch (e) {
        error = e.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),
          _buildControlPanel(context),
          const SizedBox(height: 16),
          if (error != null)
            _buildErrorCard(context)
          else if (v4Base != null || v6Base != null)
            _buildSummaryCard(context),
          if (error == null && (v4Base != null || v6Base != null))
            const SizedBox(height: 12),
          if (v4Base != null && error == null)
            _buildIpv4Report(v4rows ?? const []),
          if (v6Base != null && error == null)
            _buildIpv6Report(v6rows ?? const []),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.call_split,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subnetting',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Calcula red, broadcast, hosts y transicion /p -> /q.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProtocolSelector(),
          const SizedBox(height: 14),
          _buildClassicInputs(),
        ],
      ),
    );
  }

  Widget _buildProtocolSelector() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.filter_4),
          label: Text('IPv4'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.filter_6),
          label: Text('IPv6'),
        ),
      ],
      selected: {isIpv6},
      onSelectionChanged: (s) {
        setState(() {
          isIpv6 = s.first;
          if (isIpv6) {
            addressCtrl.text = '2001:db8:1200::';
            originalPrefixCtrl.text = '48';
            newPrefixCtrl.clear();
          } else {
            addressCtrl.text = '192.168.0.1';
            originalPrefixCtrl.text = '24';
            newPrefixCtrl.clear();
          }
        });
        _calculate();
      },
    );
  }

  Widget _buildClassicInputs() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Address (host o red)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const Text('/'),
        SizedBox(
          width: 140,
          child: TextField(
            controller: originalPrefixCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Netmask (ej. 24)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const Text('move to:'),
        SizedBox(
          width: 150,
          child: TextField(
            controller: newPrefixCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nueva mascara',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Calcular'),
        ),
        OutlinedButton.icon(
          onPressed: _showSubnettingHelp,
          icon: const Icon(Icons.info_outline),
          label: const Text('Ayuda'),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC928),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB77900)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.bolt, size: 20, color: Color(0xFF4A3500)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _summaryOneLine(),
                  softWrap: false,
                  style: const TextStyle(
                    color: Color(0xFF2D2200),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryOneLine() {
    if (!hasMaskTransition) {
      if (isIpv6) {
        final base = v6Base!;
        return 'Red base: ${base.networkStart.canonical}/${base.length} | Rango: ${base.networkStart.canonical} - ${base.networkEnd.canonical} | IPv6 no usa broadcast';
      }
      final base = v4Base!;
      return 'Red base: ${base.network.dotted}/${base.prefix.length} | Broadcast: ${base.broadcast.dotted} | Hosts: ${base.hostCount} (${base.hostMin!.dotted}-${base.hostMax!.dotted}) | Red=IP AND mascara; Broadcast=Red OR wildcard';
    }

    if (resolvedNewLength == originalLength) {
      return 'Sin cambio: /$originalLength y /$resolvedNewLength describen la misma red';
    }

    if (resolvedNewLength > originalLength) {
      final borrowedBits = resolvedNewLength - originalLength;
      final subnets = BigInt.one << borrowedBits;
      if (isIpv6) {
        final addressesPerSubnet = BigInt.two.pow(128 - resolvedNewLength);
        return 'Dividir /$originalLength -> /$resolvedNewLength | Subredes: 2^$borrowedBits=$subnets | Direcciones/subred: $addressesPerSubnet | IPv6 no usa broadcast';
      }
      final hostsPerSubnet = v4rows!.isEmpty ? 0 : v4rows!.first.hostCount;
      final totalHosts = v4rows!.fold<int>(
        0,
        (sum, row) => sum + row.hostCount,
      );
      final blockSize = BigInt.one << (32 - resolvedNewLength);
      return 'Dividir /$originalLength -> /$resolvedNewLength | Subredes: 2^$borrowedBits=$subnets | Salto: $blockSize | Hosts/subred: $hostsPerSubnet | Total: $totalHosts';
    }

    final mergedBits = originalLength - resolvedNewLength;
    final mergedNetworks = BigInt.one << mergedBits;
    if (isIpv6) {
      final row = v6rows!.single;
      return 'Agregar /$originalLength -> /$resolvedNewLength | Agrupa: 2^$mergedBits=$mergedNetworks redes | Superred: ${row.networkStart.canonical}/$resolvedNewLength | IPv6 no usa broadcast';
    }
    final row = v4rows!.single;
    return 'Agregar /$originalLength -> /$resolvedNewLength | Agrupa: 2^$mergedBits=$mergedNetworks redes | Superred: ${row.network.dotted}/$resolvedNewLength | Rango: ${row.network.dotted}-${row.broadcast.dotted}';
  }

  void _showSubnettingHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Text('Ayuda de subnetting'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _helpStep('1', 'Elige IPv4 o IPv6.'),
                _helpStep(
                  '2',
                  'Address acepta una IP de host o una direccion de red.',
                ),
                _helpStep(
                  '3',
                  'Netmask es el prefijo actual, por ejemplo /24.',
                ),
                _helpStep('4', 'Deja move to vacio para ver solo la red base.'),
                _helpStep(
                  '5',
                  'move to mayor divide en subredes; menor crea una superred.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Widget _helpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildIpv4Report(List<Ipv4SubnetRow> rows) {
    final input = v4Input!;
    final base = v4Base!;
    final p = base.prefix;
    final totalHosts = rows.fold<int>(0, (sum, row) => sum + row.hostCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportCard(
          children: [
            BitRow(
              label: 'Address',
              spans: ipv4BitSpans(
                input.value,
                originalLength,
                prefixColor: Colors.green,
              ),
              trailing: input.dotted,
            ),
            BitRow(
              label: 'Netmask',
              spans: ipv4BitSpans(
                p.mask.value,
                originalLength,
                prefixColor: Colors.red,
              ),
              trailing: '${p.mask.dotted} = /${p.length}',
            ),
            BitRow(
              label: 'Wildcard',
              spans: ipv4BitSpans(
                p.wildcard.value,
                originalLength,
                prefixColor: Colors.grey,
              ),
              trailing: p.wildcard.dotted,
            ),
            const Text('=>', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _ipv4NetworkLines(base, showNetmask: false),
            if (hasEffectiveMaskTransition) ..._buildIpv4TransitionSummary(),
          ],
        ),
        if (hasEffectiveMaskTransition) ...[
          const SizedBox(height: 12),
          Text(
            'Subnets: ${rows.length}   Hosts: $totalHosts',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map(
            (entry) => _ipv4SubnetCard(entry.key + 1, entry.value),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildIpv4TransitionSummary() {
    final targetMask = Ipv4Prefix.maskForLength(resolvedNewLength);
    final targetWildcard = targetMask.complement;

    return [
      const Divider(height: 22),
      Text(
        _transitionTitle(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      BitRow(
        label: 'Netmask',
        spans: ipv4BitSpans(
          targetMask.value,
          resolvedNewLength,
          prefixColor: Colors.red,
        ),
        trailing: '${targetMask.dotted} = /$resolvedNewLength',
      ),
      BitRow(
        label: 'Wildcard',
        spans: ipv4BitSpans(
          targetWildcard.value,
          resolvedNewLength,
          prefixColor: Colors.grey,
        ),
        trailing: targetWildcard.dotted,
      ),
    ];
  }

  String _transitionTitle() {
    if (resolvedNewLength > originalLength) {
      return 'Subnets after transition from /$originalLength to /$resolvedNewLength';
    }
    if (resolvedNewLength < originalLength) {
      return 'Supernet after transition from /$originalLength to /$resolvedNewLength';
    }
    return 'Same network /$resolvedNewLength';
  }

  Widget _reportCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _ipv4NetworkLines(Ipv4SubnetRow row, {bool showNetmask = true}) {
    final p = row.prefix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNetmask)
          BitRow(
            label: 'Netmask',
            spans: ipv4BitSpans(
              p.mask.value,
              p.length,
              prefixColor: Colors.red,
            ),
            trailing: '${p.mask.dotted} = /${p.length}',
          ),
        BitRow(
          label: 'Network',
          spans: ipv4BitSpans(
            row.network.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: '${row.network.dotted}/${p.length}',
        ),
        BitRow(
          label: 'HostMin',
          spans: ipv4BitSpans(
            row.hostMin!.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.hostMin!.dotted,
        ),
        BitRow(
          label: 'HostMax',
          spans: ipv4BitSpans(
            row.hostMax!.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.hostMax!.dotted,
        ),
        BitRow(
          label: 'Broadcast',
          spans: ipv4BitSpans(
            row.broadcast.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.broadcast.dotted,
        ),
        Text(
          'Hosts/Net: ${row.hostCount}   ${row.classification.label}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _ipv4SubnetCard(int index, Ipv4SubnetRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${row.network.dotted}/${row.prefix.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ipv4NetworkLines(row),
          ],
        ),
      ),
    );
  }

  Widget _buildIpv6Report(List<Ipv6Prefix> rows) {
    final input = v6Input!;
    final base = v6Base!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportCard(
          children: [
            Text('Address: ${input.canonical}/${base.length}'),
            Text('Network: ${base.networkStart.canonical}/${base.length}'),
            Text('End: ${base.networkEnd.canonical}'),
            if (hasEffectiveMaskTransition) ...[
              const Divider(height: 22),
              Text(
                _transitionTitle(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        if (hasEffectiveMaskTransition) ...[
          ...rows.asMap().entries.map(
            (entry) => _ipv6SubnetCard(entry.key + 1, entry.value),
          ),
          Text(
            'Subnets: ${rows.length}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _ipv6SubnetCard(int index, Ipv6Prefix p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${p.networkStart.canonical}/${p.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Inicio: ${p.networkStart.canonical}'),
            Text('Fin: ${p.networkEnd.canonical}'),
            Text('Direcciones: ${p.totalAddresses}'),
          ],
        ),
      ),
    );
  }
}
