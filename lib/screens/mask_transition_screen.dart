import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_localization.dart';
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

enum _SubnetMode { maskTransition, vlsm }

class _VlsmAllocation {
  final int requestedHosts;
  final Ipv4Prefix prefix;

  const _VlsmAllocation({required this.requestedHosts, required this.prefix});

  Ipv4SubnetRow get row => Ipv4SubnetRow(prefix);

  int get blockSize => 1 << (32 - prefix.length);
}

class _Ipv6VlsmAllocation {
  final BigInt requestedAddresses;
  final Ipv6Prefix prefix;

  const _Ipv6VlsmAllocation({
    required this.requestedAddresses,
    required this.prefix,
  });

  BigInt get blockSize => BigInt.two.pow(128 - prefix.length);
}

class MaskTransitionScreen extends StatefulWidget {
  const MaskTransitionScreen({super.key});
  @override
  State<MaskTransitionScreen> createState() => _MaskTransitionScreenState();
}

class _MaskTransitionScreenState extends State<MaskTransitionScreen> {
  bool isIpv6 = false;
  _SubnetMode mode = _SubnetMode.maskTransition;

  final addressCtrl = TextEditingController(text: '192.168.0.1');
  final originalPrefixCtrl = TextEditingController(text: '24');
  final newPrefixCtrl = TextEditingController();
  final vlsmCountCtrl = TextEditingController(text: '3');
  final List<TextEditingController> vlsmHostCtrls = [
    TextEditingController(text: '300'),
    TextEditingController(text: '100'),
    TextEditingController(text: '50'),
  ];

  String? error;
  List<Ipv4SubnetRow>? v4rows;
  List<Ipv6Prefix>? v6rows;
  List<_VlsmAllocation>? vlsmRows;
  List<_Ipv6VlsmAllocation>? vlsmV6Rows;
  BigInt? v6TotalSubnets;
  bool v6RowsPreviewOnly = false;
  Ipv4Address? v4Input;
  Ipv4SubnetRow? v4Base;
  Ipv6Address? v6Input;
  Ipv6Prefix? v6Base;
  Ipv4Prefix? vlsmBase;
  Ipv6Prefix? vlsmV6Base;
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

  @override
  void dispose() {
    addressCtrl.dispose();
    originalPrefixCtrl.dispose();
    newPrefixCtrl.dispose();
    vlsmCountCtrl.dispose();
    for (final ctrl in vlsmHostCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  int _parseRequiredInt(String text, String fieldLabel) {
    final v = int.tryParse(text.trim());
    if (v == null) {
      throw _InputException('$fieldLabel debe ser un numero entero.');
    }
    return v;
  }

  void _clearResults() {
    error = null;
    v4rows = null;
    v6rows = null;
    vlsmRows = null;
    vlsmV6Rows = null;
    v6TotalSubnets = null;
    v6RowsPreviewOnly = false;
    v4Input = null;
    v4Base = null;
    v6Input = null;
    v6Base = null;
    vlsmBase = null;
    vlsmV6Base = null;
    hasMaskTransition = false;
  }

  void _calculate() {
    if (mode == _SubnetMode.vlsm) {
      _calculateVlsm();
      return;
    }

    setState(() {
      _clearResults();

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
            if (q > p) {
              final total = BigInt.two.pow(q - p);
              v6TotalSubnets = total;
              if (total > BigInt.from(4096)) {
                final base = Ipv6Prefix(addr, p);
                v6rows = [Ipv6Prefix(base.networkStart, q)];
                v6RowsPreviewOnly = true;
              } else {
                v6rows = Ipv6Subnetting.transitionMask(addr, p, q);
              }
            } else {
              v6rows = Ipv6Subnetting.transitionMask(addr, p, q);
              v6TotalSubnets = BigInt.one;
            }
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

  int _parseVlsmCount() {
    final count = _parseRequiredInt(
      vlsmCountCtrl.text,
      'La cantidad de subredes',
    );
    if (count < 1 || count > 32) {
      throw _InputException('La cantidad de subredes debe estar entre 1 y 32.');
    }
    return count;
  }

  void _syncVlsmHostControllers(int count) {
    while (vlsmHostCtrls.length < count) {
      vlsmHostCtrls.add(TextEditingController(text: '10'));
    }
    while (vlsmHostCtrls.length > count) {
      vlsmHostCtrls.removeLast().dispose();
    }
  }

  void _applyVlsmCount() {
    setState(() {
      try {
        _clearResults();
        _syncVlsmHostControllers(_parseVlsmCount());
      } catch (e) {
        error = e.toString();
      }
    });
  }

  void _calculateVlsm() {
    setState(() {
      _clearResults();

      try {
        final count = _parseVlsmCount();
        _syncVlsmHostControllers(count);

        final prefixLength = _parseRequiredInt(
          originalPrefixCtrl.text,
          'El prefijo base',
        );

        if (isIpv6) {
          final addr = Ipv6Address.parse(addressCtrl.text);
          final base = Ipv6Prefix(addr, prefixLength);
          final normalizedBase = Ipv6Prefix(base.networkStart, prefixLength);
          final requirements = <BigInt>[];

          for (var i = 0; i < count; i++) {
            final raw = vlsmHostCtrls[i].text.trim();
            final addresses = BigInt.tryParse(raw);
            if (addresses == null) {
              throw _InputException(
                'Direcciones de subred ${i + 1} debe ser un numero entero.',
              );
            }
            if (addresses < BigInt.one) {
              throw _InputException(
                'Direcciones de subred ${i + 1} debe ser mayor que 0.',
              );
            }
            requirements.add(addresses);
          }

          final prefixes = Ipv6Subnetting.vlsm(normalizedBase, requirements);
          final allocations =
              List.generate(
                prefixes.length,
                (i) => _Ipv6VlsmAllocation(
                  requestedAddresses: requirements[i],
                  prefix: prefixes[i],
                ),
              )..sort(
                (a, b) => a.prefix.networkStart.value.compareTo(
                  b.prefix.networkStart.value,
                ),
              );

          v6Input = addr;
          v6Base = normalizedBase;
          vlsmV6Base = normalizedBase;
          vlsmV6Rows = allocations;
        } else {
          final addr = Ipv4Address.parse(addressCtrl.text);
          final base = Ipv4Prefix(addr, prefixLength);
          final normalizedBase = Ipv4Prefix(base.network, prefixLength);
          final requirements = <int>[];

          for (var i = 0; i < count; i++) {
            final hosts = _parseRequiredInt(
              vlsmHostCtrls[i].text,
              'Hosts de subred ${i + 1}',
            );
            if (hosts < 1) {
              throw _InputException(
                'Hosts de subred ${i + 1} debe ser mayor que 0.',
              );
            }
            requirements.add(hosts);
          }

          final prefixes = Ipv4Subnetting.vlsm(normalizedBase, requirements);
          final allocations =
              List.generate(
                prefixes.length,
                (i) => _VlsmAllocation(
                  requestedHosts: requirements[i],
                  prefix: prefixes[i],
                ),
              )..sort(
                (a, b) =>
                    a.prefix.network.value.compareTo(b.prefix.network.value),
              );

          v4Input = addr;
          v4Base = Ipv4SubnetRow(normalizedBase);
          vlsmBase = normalizedBase;
          vlsmRows = allocations;
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
          else if (mode == _SubnetMode.vlsm &&
              (vlsmRows != null || vlsmV6Rows != null))
            _buildSummaryCard(context)
          else if (v4Base != null || v6Base != null)
            _buildSummaryCard(context),
          if (error == null &&
              (v4Base != null ||
                  v6Base != null ||
                  vlsmRows != null ||
                  vlsmV6Rows != null))
            const SizedBox(height: 12),
          if (mode == _SubnetMode.vlsm && vlsmRows != null && error == null)
            _buildVlsmReport(vlsmRows!)
          else if (mode == _SubnetMode.vlsm &&
              vlsmV6Rows != null &&
              error == null)
            _buildIpv6VlsmReport(vlsmV6Rows!)
          else if (v4Base != null && error == null)
            _buildIpv4Report(v4rows ?? const []),
          if (mode != _SubnetMode.vlsm && v6Base != null && error == null)
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
                context.t('Subnetting'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                context.t(
                  'Calcula red, broadcast, hosts, transicion /p -> /q y VLSM.',
                ),
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
          _buildModeSelector(context),
          const SizedBox(height: 14),
          if (mode == _SubnetMode.maskTransition) ...[
            _buildProtocolSelector(context),
            const SizedBox(height: 14),
            _buildClassicInputs(context),
          ] else
            _buildVlsmInputs(context),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return SegmentedButton<_SubnetMode>(
      segments: [
        ButtonSegment(
          value: _SubnetMode.maskTransition,
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: Text(context.t('Transición de máscara')),
        ),
        ButtonSegment(
          value: _SubnetMode.vlsm,
          icon: const Icon(Icons.account_tree_outlined, size: 16),
          label: Text(context.t('VLSM por hosts')),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) {
        setState(() {
          mode = s.first;
          _clearResults();
          if (mode == _SubnetMode.vlsm) {
            isIpv6 = false;
            addressCtrl.text = '192.168.0.0';
            originalPrefixCtrl.text = '22';
            newPrefixCtrl.clear();
            vlsmCountCtrl.text = '3';
            _syncVlsmHostControllers(3);
            vlsmHostCtrls[0].text = '300';
            vlsmHostCtrls[1].text = '100';
            vlsmHostCtrls[2].text = '50';
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

  Widget _buildProtocolSelector(BuildContext context) {
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
          if (mode == _SubnetMode.vlsm) {
            if (isIpv6) {
              addressCtrl.text = '2001:db8:1200::';
              originalPrefixCtrl.text = '120';
              vlsmCountCtrl.text = '2';
              _syncVlsmHostControllers(2);
              vlsmHostCtrls[0].text = '100';
              vlsmHostCtrls[1].text = '30';
            } else {
              addressCtrl.text = '192.168.0.0';
              originalPrefixCtrl.text = '22';
              vlsmCountCtrl.text = '3';
              _syncVlsmHostControllers(3);
              vlsmHostCtrls[0].text = '300';
              vlsmHostCtrls[1].text = '100';
              vlsmHostCtrls[2].text = '50';
            }
          } else {
            if (isIpv6) {
              addressCtrl.text = '2001:db8:1200::';
              originalPrefixCtrl.text = '48';
              newPrefixCtrl.clear();
            } else {
              addressCtrl.text = '192.168.0.1';
              originalPrefixCtrl.text = '24';
              newPrefixCtrl.clear();
            }
          }
          _clearResults();
        });
        _calculate();
      },
    );
  }

  Widget _buildClassicInputs(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: addressCtrl,
            decoration: InputDecoration(
              labelText: context.t('Address (host o red)'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const Text('/'),
        SizedBox(
          width: 140,
          child: TextField(
            controller: originalPrefixCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.t('Netmask (ej. 24)'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Text(context.t('move to:')),
        SizedBox(
          width: 150,
          child: TextField(
            controller: newPrefixCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.t('Nueva mascara'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_outlined),
          label: Text(context.t('Calcular')),
        ),
        OutlinedButton.icon(
          onPressed: _showSubnettingHelp,
          icon: const Icon(Icons.info_outline),
          label: Text(context.t('Ayuda')),
        ),
      ],
    );
  }

  Widget _buildVlsmInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProtocolSelector(context),
        const SizedBox(height: 14),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: context.t(
                    isIpv6 ? 'Red base IPv6' : 'Red base IPv4',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const Text('/'),
            SizedBox(
              width: 140,
              child: TextField(
                controller: originalPrefixCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.t('Prefijo base'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: vlsmCountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.t('Cantidad de subredes'),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _applyVlsmCount(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _applyVlsmCount,
              icon: const Icon(Icons.playlist_add),
              label: Text(context.t('Crear campos')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          context.t(
            isIpv6
                ? 'Direcciones requeridas por subred'
                : 'Hosts requeridos por subred',
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (var i = 0; i < vlsmHostCtrls.length; i++)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: vlsmHostCtrls[i],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${context.t('Subred')} ${i + 1}',
                    border: const OutlineInputBorder(),
                    helperText: context.t(isIpv6 ? 'Direcciones' : 'Hosts'),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _calculateVlsm,
              icon: const Icon(Icons.account_tree_outlined),
              label: Text(context.t('Calcular VLSM')),
            ),
            OutlinedButton.icon(
              onPressed: _showSubnettingHelp,
              icon: const Icon(Icons.info_outline),
              label: Text(context.t('Ayuda')),
            ),
          ],
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

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.t(label)} ${context.t('copiado')}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _copyButton(String label, String value, {IconData icon = Icons.copy}) {
    return OutlinedButton.icon(
      onPressed: () => _copyToClipboard(label, value),
      icon: Icon(icon, size: 16),
      label: Text(context.t(label)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _copyActions(List<Widget> actions) {
    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  String _summaryOneLine() {
    if (mode == _SubnetMode.vlsm) {
      if (isIpv6) {
        final base = vlsmV6Base!;
        final rows = vlsmV6Rows!;
        final requestedAddresses = rows.fold<BigInt>(
          BigInt.zero,
          (sum, row) => sum + row.requestedAddresses,
        );
        final usedAddresses = rows.fold<BigInt>(
          BigInt.zero,
          (sum, row) => sum + row.blockSize,
        );
        final freeAddresses = base.totalAddresses - usedAddresses;
        return 'VLSM IPv6 | Base: ${base.networkStart.canonical}/${base.length} | Subredes: ${rows.length} | Direcciones pedidas: $requestedAddresses | Direcciones asignadas: $usedAddresses | Libres: $freeAddresses';
      }

      final base = vlsmBase!;
      final rows = vlsmRows!;
      final requestedHosts = rows.fold<int>(
        0,
        (sum, row) => sum + row.requestedHosts,
      );
      final usableHosts = rows.fold<int>(
        0,
        (sum, row) => sum + row.row.hostCount,
      );
      final usedAddresses = rows.fold<int>(
        0,
        (sum, row) => sum + row.blockSize,
      );
      final freeAddresses = base.totalAddresses.toInt() - usedAddresses;
      return 'VLSM | Base: ${base.network.dotted}/${base.length} | Subredes: ${rows.length} | Hosts pedidos: $requestedHosts | Hosts útiles: $usableHosts | Direcciones libres: $freeAddresses';
    }

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
        if (v6RowsPreviewOnly) {
          return 'Dividir /$originalLength -> /$resolvedNewLength | Subredes creadas: $subnets | Mostrando solo la primera | Direcciones/subred: $addressesPerSubnet | IPv6 no usa broadcast';
        }
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
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Text(context.t('Ayuda de subnetting')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: mode == _SubnetMode.vlsm
                  ? [
                      _helpStep(
                        '1',
                        context.t('Ingresa la red base IPv4 y su prefijo.'),
                      ),
                      _helpStep(
                        '2',
                        context.t(
                          'Indica cuantas subredes necesitas y crea los campos.',
                        ),
                      ),
                      _helpStep(
                        '3',
                        context.t(
                          'Escribe los hosts requeridos para cada subred.',
                        ),
                      ),
                      _helpStep(
                        '4',
                        context.t(
                          'VLSM ordena de mayor a menor para evitar solapamientos.',
                        ),
                      ),
                      _helpStep(
                        '5',
                        context.t(
                          'Cada bloque se redondea a la siguiente potencia de dos.',
                        ),
                      ),
                    ]
                  : [
                      _helpStep('1', context.t('Elige IPv4 o IPv6.')),
                      _helpStep(
                        '2',
                        context.t(
                          'Address acepta una IP de host o una direccion de red.',
                        ),
                      ),
                      _helpStep(
                        '3',
                        context.t(
                          'Netmask es el prefijo actual, por ejemplo /24.',
                        ),
                      ),
                      _helpStep(
                        '4',
                        context.t(
                          'Deja move to vacio para ver solo la red base.',
                        ),
                      ),
                      _helpStep(
                        '5',
                        context.t(
                          'move to mayor divide en subredes; menor crea una superred.',
                        ),
                      ),
                    ],
            ),
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
            _copyActions([
              _copyButton('Copiar base', _ipv4BaseText(base)),
              if (hasEffectiveMaskTransition)
                _copyButton(
                  'Copiar todo',
                  _ipv4FullText(base, rows),
                  icon: Icons.content_copy,
                ),
            ]),
            const SizedBox(height: 10),
            _copyableBitRow(
              label: 'Address',
              spans: ipv4BitSpans(
                input.value,
                originalLength,
                prefixColor: Colors.green,
              ),
              trailing: input.dotted,
              copyValue: input.dotted,
            ),
            _copyableBitRow(
              label: 'Netmask',
              spans: ipv4BitSpans(
                p.mask.value,
                originalLength,
                prefixColor: Colors.red,
              ),
              trailing: '${p.mask.dotted} = /${p.length}',
              copyValue: '${p.mask.dotted} = /${p.length}',
            ),
            _copyableBitRow(
              label: 'Wildcard',
              spans: ipv4BitSpans(
                p.wildcard.value,
                originalLength,
                prefixColor: Colors.grey,
              ),
              trailing: p.wildcard.dotted,
              copyValue: p.wildcard.dotted,
            ),
            const Text('=>', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _ipv4NetworkLines(base, showNetmask: false, copyFields: true),
            if (hasEffectiveMaskTransition) ..._buildIpv4TransitionSummary(),
          ],
        ),
        if (hasEffectiveMaskTransition) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subnets: ${rows.length}   Hosts: $totalHosts',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _copyButton(
                'Copiar subredes',
                _ipv4AllSubnetsText(rows),
                icon: Icons.copy_all,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map(
            (entry) => _ipv4SubnetCard(entry.key + 1, entry.value),
          ),
        ],
      ],
    );
  }

  String _ipv4BaseText(Ipv4SubnetRow row) {
    final p = row.prefix;
    return [
      'Address: ${v4Input!.dotted}',
      'Netmask: ${p.mask.dotted} = /${p.length}',
      'Wildcard: ${p.wildcard.dotted}',
      'Network: ${row.network.dotted}/${p.length}',
      'HostMin: ${row.hostMin!.dotted}',
      'HostMax: ${row.hostMax!.dotted}',
      'Broadcast: ${row.broadcast.dotted}',
      'Hosts/Net: ${row.hostCount}',
      'Clase: ${row.classification.label}',
    ].join('\n');
  }

  String _ipv4SubnetText(int index, Ipv4SubnetRow row) {
    final p = row.prefix;
    return [
      '$index. ${row.network.dotted}/${p.length}',
      'Netmask: ${p.mask.dotted} = /${p.length}',
      'Wildcard: ${p.wildcard.dotted}',
      'Network: ${row.network.dotted}/${p.length}',
      'HostMin: ${row.hostMin!.dotted}',
      'HostMax: ${row.hostMax!.dotted}',
      'Broadcast: ${row.broadcast.dotted}',
      'Hosts/Net: ${row.hostCount}',
      'Clase: ${row.classification.label}',
    ].join('\n');
  }

  String _ipv4AllSubnetsText(List<Ipv4SubnetRow> rows) {
    return rows
        .asMap()
        .entries
        .map((entry) => _ipv4SubnetText(entry.key + 1, entry.value))
        .join('\n\n');
  }

  String _ipv4FullText(Ipv4SubnetRow base, List<Ipv4SubnetRow> rows) {
    final parts = [_ipv4BaseText(base)];
    if (rows.isNotEmpty) {
      parts.add('Subnets: ${rows.length}');
      parts.add(_ipv4AllSubnetsText(rows));
    }
    return parts.join('\n\n');
  }

  String _vlsmAllocationText(int index, _VlsmAllocation allocation) {
    final row = allocation.row;
    final p = allocation.prefix;
    return [
      '$index. Solicitud: ${allocation.requestedHosts} hosts',
      'Prefix: ${row.network.dotted}/${p.length}',
      'Netmask: ${p.mask.dotted} = /${p.length}',
      'Wildcard: ${p.wildcard.dotted}',
      'Network: ${row.network.dotted}/${p.length}',
      'HostMin: ${row.hostMin!.dotted}',
      'HostMax: ${row.hostMax!.dotted}',
      'Broadcast: ${row.broadcast.dotted}',
      'Hosts útiles: ${row.hostCount}',
      'Bloque: ${allocation.blockSize} direcciones',
    ].join('\n');
  }

  String _vlsmPlanText(List<_VlsmAllocation> rows) {
    return [
      'VLSM base: ${vlsmBase!.network.dotted}/${vlsmBase!.length}',
      'Subredes: ${rows.length}',
      ...rows.asMap().entries.map(
        (entry) => _vlsmAllocationText(entry.key + 1, entry.value),
      ),
    ].join('\n\n');
  }

  String _ipv6VlsmAllocationText(int index, _Ipv6VlsmAllocation allocation) {
    final p = allocation.prefix;
    return [
      '$index. Solicitud: ${allocation.requestedAddresses} direcciones',
      'Prefix: ${p.networkStart.canonical}/${p.length}',
      'Inicio: ${p.networkStart.canonical}',
      'Fin: ${p.networkEnd.canonical}',
      'Direcciones asignadas: ${allocation.blockSize}',
      'IPv6 no usa broadcast',
    ].join('\n');
  }

  String _ipv6VlsmPlanText(List<_Ipv6VlsmAllocation> rows) {
    return [
      'VLSM IPv6 base: ${vlsmV6Base!.networkStart.canonical}/${vlsmV6Base!.length}',
      'Subredes: ${rows.length}',
      ...rows.asMap().entries.map(
        (entry) => _ipv6VlsmAllocationText(entry.key + 1, entry.value),
      ),
    ].join('\n\n');
  }

  String _ipv4FieldText(Ipv4SubnetRow row, String field) {
    final p = row.prefix;
    switch (field) {
      case 'Netmask':
        return '${p.mask.dotted} = /${p.length}';
      case 'Network':
        return '${row.network.dotted}/${p.length}';
      case 'HostMin':
        return row.hostMin!.dotted;
      case 'HostMax':
        return row.hostMax!.dotted;
      case 'Broadcast':
        return row.broadcast.dotted;
      case 'Wildcard':
        return p.wildcard.dotted;
      default:
        return '';
    }
  }

  Widget _ipv4SubnetCopyActions(int index, Ipv4SubnetRow row) {
    return _copyActions([_copyButton('Subred', _ipv4SubnetText(index, row))]);
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
      _copyableBitRow(
        label: 'Netmask',
        spans: ipv4BitSpans(
          targetMask.value,
          resolvedNewLength,
          prefixColor: Colors.red,
        ),
        trailing: '${targetMask.dotted} = /$resolvedNewLength',
        copyValue: '${targetMask.dotted} = /$resolvedNewLength',
      ),
      _copyableBitRow(
        label: 'Wildcard',
        spans: ipv4BitSpans(
          targetWildcard.value,
          resolvedNewLength,
          prefixColor: Colors.grey,
        ),
        trailing: targetWildcard.dotted,
        copyValue: targetWildcard.dotted,
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

  Widget _ipv4NetworkLines(
    Ipv4SubnetRow row, {
    bool showNetmask = true,
    bool copyFields = false,
  }) {
    final p = row.prefix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNetmask)
          _copyableBitRow(
            label: 'Netmask',
            spans: ipv4BitSpans(
              p.mask.value,
              p.length,
              prefixColor: Colors.red,
            ),
            trailing: '${p.mask.dotted} = /${p.length}',
            copyValue: copyFields ? _ipv4FieldText(row, 'Netmask') : null,
          ),
        _copyableBitRow(
          label: 'Network',
          spans: ipv4BitSpans(
            row.network.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: '${row.network.dotted}/${p.length}',
          copyValue: copyFields ? _ipv4FieldText(row, 'Network') : null,
        ),
        _copyableBitRow(
          label: 'HostMin',
          spans: ipv4BitSpans(
            row.hostMin!.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.hostMin!.dotted,
          copyValue: copyFields ? _ipv4FieldText(row, 'HostMin') : null,
        ),
        _copyableBitRow(
          label: 'HostMax',
          spans: ipv4BitSpans(
            row.hostMax!.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.hostMax!.dotted,
          copyValue: copyFields ? _ipv4FieldText(row, 'HostMax') : null,
        ),
        _copyableBitRow(
          label: 'Broadcast',
          spans: ipv4BitSpans(
            row.broadcast.value,
            p.length,
            prefixColor: Colors.green,
          ),
          trailing: row.broadcast.dotted,
          copyValue: copyFields ? _ipv4FieldText(row, 'Broadcast') : null,
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

  Widget _copyableBitRow({
    required String label,
    required List<InlineSpan> spans,
    required String trailing,
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              context.t(label),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                children: spans,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (copyValue != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _copyToClipboard(label, copyValue),
              icon: const Icon(Icons.copy, size: 16),
              tooltip: '${context.t('Copiar')} ${context.t(label)}',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 28),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
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
            _ipv4SubnetCopyActions(index, row),
            const SizedBox(height: 8),
            _ipv4NetworkLines(row, copyFields: true),
          ],
        ),
      ),
    );
  }

  Widget _buildVlsmReport(List<_VlsmAllocation> rows) {
    final base = vlsmBase!;
    final baseRow = Ipv4SubnetRow(base);
    final usedAddresses = rows.fold<int>(
      0,
      (sum, allocation) => sum + allocation.blockSize,
    );
    final freeAddresses = base.totalAddresses.toInt() - usedAddresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportCard(
          children: [
            _copyActions([
              _copyButton(
                'Copiar plan VLSM',
                _vlsmPlanText(rows),
                icon: Icons.copy_all,
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              context.t('Red base VLSM'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _copyableBitRow(
              label: 'Network',
              spans: ipv4BitSpans(
                base.network.value,
                base.length,
                prefixColor: Colors.green,
              ),
              trailing: '${base.network.dotted}/${base.length}',
              copyValue: '${base.network.dotted}/${base.length}',
            ),
            _copyableBitRow(
              label: 'Netmask',
              spans: ipv4BitSpans(
                base.mask.value,
                base.length,
                prefixColor: Colors.red,
              ),
              trailing: '${base.mask.dotted} = /${base.length}',
              copyValue: '${base.mask.dotted} = /${base.length}',
            ),
            _copyableBitRow(
              label: 'Broadcast',
              spans: ipv4BitSpans(
                baseRow.broadcast.value,
                base.length,
                prefixColor: Colors.green,
              ),
              trailing: baseRow.broadcast.dotted,
              copyValue: baseRow.broadcast.dotted,
            ),
            const Divider(height: 22),
            Text(
              '${context.t('Direcciones libres')}: $freeAddresses',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${context.t('Plan VLSM')}: ${rows.length} ${context.t('Subredes').toLowerCase()}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _copyButton(
              'Copiar plan VLSM',
              _vlsmPlanText(rows),
              icon: Icons.copy_all,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map(
          (entry) => _vlsmSubnetCard(entry.key + 1, entry.value),
        ),
      ],
    );
  }

  Widget _vlsmSubnetCard(int index, _VlsmAllocation allocation) {
    final row = allocation.row;
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
                    '${row.network.dotted}/${allocation.prefix.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${allocation.requestedHosts} ${context.t('hosts pedidos')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _copyActions([
              _copyButton(
                'Copiar subred',
                _vlsmAllocationText(index, allocation),
              ),
            ]),
            const SizedBox(height: 8),
            _ipv4NetworkLines(row, copyFields: true),
            const SizedBox(height: 4),
            Text(
              '${context.t('Bloque')}: ${allocation.blockSize} ${context.t('direcciones')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIpv6VlsmReport(List<_Ipv6VlsmAllocation> rows) {
    final base = vlsmV6Base!;
    final usedAddresses = rows.fold<BigInt>(
      BigInt.zero,
      (sum, allocation) => sum + allocation.blockSize,
    );
    final freeAddresses = base.totalAddresses - usedAddresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportCard(
          children: [
            _copyActions([
              _copyButton(
                'Copiar plan VLSM',
                _ipv6VlsmPlanText(rows),
                icon: Icons.copy_all,
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              context.t('Red base VLSM'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _copyableTextRow(
              'Prefijo',
              '${base.networkStart.canonical}/${base.length}',
            ),
            _copyableTextRow('Inicio', base.networkStart.canonical),
            _copyableTextRow('Fin', base.networkEnd.canonical),
            _copyableTextRow('Direcciones', base.totalAddresses.toString()),
            const Divider(height: 22),
            Text(
              '${context.t('Direcciones libres')}: $freeAddresses',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                'IPv6 no usa broadcast; para LANs normalmente se recomienda /64.',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${context.t('Plan VLSM')}: ${rows.length} ${context.t('Subredes').toLowerCase()}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _copyButton(
              'Copiar plan VLSM',
              _ipv6VlsmPlanText(rows),
              icon: Icons.copy_all,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map(
          (entry) => _ipv6VlsmSubnetCard(entry.key + 1, entry.value),
        ),
      ],
    );
  }

  Widget _ipv6VlsmSubnetCard(int index, _Ipv6VlsmAllocation allocation) {
    final p = allocation.prefix;
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
                Text(
                  '${allocation.requestedAddresses} ${context.t('direcciones pedidas')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _copyActions([
              _copyButton(
                'Copiar subred',
                _ipv6VlsmAllocationText(index, allocation),
              ),
            ]),
            const SizedBox(height: 8),
            _copyableTextRow(
              'Prefijo',
              '${p.networkStart.canonical}/${p.length}',
            ),
            _copyableTextRow('Inicio', p.networkStart.canonical),
            _copyableTextRow('Fin', p.networkEnd.canonical),
            _copyableTextRow('Direcciones', allocation.blockSize.toString()),
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
            _copyActions([
              _copyButton('Copiar base', _ipv6BaseText(base)),
              if (hasEffectiveMaskTransition)
                _copyButton(
                  'Copiar todo',
                  _ipv6FullText(base, rows),
                  icon: Icons.content_copy,
                ),
            ]),
            const SizedBox(height: 10),
            _copyableTextRow('Address', '${input.canonical}/${base.length}'),
            _copyableTextRow(
              'Network',
              '${base.networkStart.canonical}/${base.length}',
            ),
            _copyableTextRow('End', base.networkEnd.canonical),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  v6RowsPreviewOnly
                      ? '${context.t('Mostrando')} ${rows.length} ${context.t('de')} ${v6TotalSubnets!} ${context.t('subredes creadas')}'
                      : 'Subnets: ${rows.length}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _copyButton(
                'Copiar subredes',
                _ipv6AllSubnetsText(rows),
                icon: Icons.copy_all,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map(
            (entry) => _ipv6SubnetCard(entry.key + 1, entry.value),
          ),
          if (v6RowsPreviewOnly) ...[
            const SizedBox(height: 8),
            _buildIpv6PreviewNotice(),
          ],
        ],
      ],
    );
  }

  Widget _buildIpv6PreviewNotice() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t('Total de subredes creadas')}: ${v6TotalSubnets!}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    'Se muestra solo la primera subred para no saturar la pantalla.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ipv6BaseText(Ipv6Prefix base) {
    return [
      'Address: ${v6Input!.canonical}/${base.length}',
      'Network: ${base.networkStart.canonical}/${base.length}',
      'End: ${base.networkEnd.canonical}',
      'Direcciones: ${base.totalAddresses}',
    ].join('\n');
  }

  String _ipv6SubnetText(int index, Ipv6Prefix p) {
    return [
      '$index. ${p.networkStart.canonical}/${p.length}',
      'Inicio: ${p.networkStart.canonical}',
      'Fin: ${p.networkEnd.canonical}',
      'Direcciones: ${p.totalAddresses}',
    ].join('\n');
  }

  String _ipv6AllSubnetsText(List<Ipv6Prefix> rows) {
    return rows
        .asMap()
        .entries
        .map((entry) => _ipv6SubnetText(entry.key + 1, entry.value))
        .join('\n\n');
  }

  String _ipv6FullText(Ipv6Prefix base, List<Ipv6Prefix> rows) {
    final parts = [_ipv6BaseText(base)];
    if (rows.isNotEmpty) {
      parts.add(
        v6RowsPreviewOnly
            ? 'Subnets total: $v6TotalSubnets\nShown: ${rows.length}'
            : 'Subnets: ${rows.length}',
      );
      parts.add(_ipv6AllSubnetsText(rows));
    }
    return parts.join('\n\n');
  }

  Widget _ipv6SubnetCopyActions(int index, Ipv6Prefix p) {
    return _copyActions([_copyButton('Subred', _ipv6SubnetText(index, p))]);
  }

  Widget _copyableTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.t(label)}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _copyToClipboard(label, value),
            icon: const Icon(Icons.copy, size: 16),
            tooltip: '${context.t('Copiar')} ${context.t(label)}',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
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
            _ipv6SubnetCopyActions(index, p),
            const SizedBox(height: 8),
            _copyableTextRow(
              'Prefijo',
              '${p.networkStart.canonical}/${p.length}',
            ),
            _copyableTextRow('Inicio', p.networkStart.canonical),
            _copyableTextRow('Fin', p.networkEnd.canonical),
            _copyableTextRow('Direcciones', p.totalAddresses.toString()),
          ],
        ),
      ),
    );
  }
}
