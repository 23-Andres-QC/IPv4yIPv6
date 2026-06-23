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

enum _Mode { byPrefix, byCount, byHosts }

class MaskTransitionScreen extends StatefulWidget {
  const MaskTransitionScreen({super.key});
  @override
  State<MaskTransitionScreen> createState() => _MaskTransitionScreenState();
}

class _MaskTransitionScreenState extends State<MaskTransitionScreen> {
  bool isIpv6 = false;
  _Mode mode = _Mode.byPrefix;

  final addressCtrl = TextEditingController(text: '192.168.0.1');
  final originalPrefixCtrl = TextEditingController(text: '24');
  final newPrefixCtrl = TextEditingController(text: '26');
  final desiredCountCtrl = TextEditingController(text: '4');
  final hostsPerSubnetCtrl = TextEditingController(text: '50');

  String? error;
  String? infoNote;
  List<Ipv4SubnetRow>? v4rows;
  List<Ipv6Prefix>? v6rows;
  int originalLength = 24;
  int resolvedNewLength = 26;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  int _parseRequiredInt(String text, String fieldLabel) {
    final v = int.tryParse(text.trim());
    if (v == null) {
      throw _InputException('$fieldLabel debe ser un número entero.');
    }
    return v;
  }

  void _calculate() {
    setState(() {
      error = null;
      infoNote = null;
      v4rows = null;
      v6rows = null;
      try {
        final p = _parseRequiredInt(originalPrefixCtrl.text, 'El prefijo original');
        originalLength = p;

        if (isIpv6) {
          final addr = Ipv6Address.parse(addressCtrl.text);
          final base = Ipv6Prefix(addr, p);
          switch (mode) {
            case _Mode.byPrefix:
              final q = _parseRequiredInt(newPrefixCtrl.text, 'El prefijo destino');
              resolvedNewLength = q;
              v6rows = Ipv6Subnetting.transitionMask(addr, p, q);
              break;
            case _Mode.byCount:
              final n = _parseRequiredInt(desiredCountCtrl.text, 'La cantidad de subredes');
              final plan = Ipv6Subnetting.byDesiredSubnetCount(base, n);
              v6rows = plan.rows;
              resolvedNewLength = plan.newLength;
              if (plan.wasRounded) {
                infoNote = 'Pediste ${plan.requestedCount} subredes. Como las subredes de igual tamaño solo '
                    'pueden crearse en potencias de 2, se redondeó hacia arriba a ${plan.deliveredCount} '
                    'subredes de /${plan.newLength}.';
              }
              break;
            case _Mode.byHosts:
              throw _InputException(
                  'El modo "hosts por subred" no aplica a IPv6: no existen direcciones reservadas de red/broadcast que restar.');
          }
        } else {
          final addr = Ipv4Address.parse(addressCtrl.text);
          final base = Ipv4Prefix(addr, p);
          switch (mode) {
            case _Mode.byPrefix:
              final q = _parseRequiredInt(newPrefixCtrl.text, 'El prefijo destino');
              resolvedNewLength = q;
              v4rows = Ipv4Subnetting.transitionMask(addr, p, q);
              break;
            case _Mode.byCount:
              final n = _parseRequiredInt(desiredCountCtrl.text, 'La cantidad de subredes');
              final plan = Ipv4Subnetting.byDesiredSubnetCount(base, n);
              v4rows = plan.rows;
              resolvedNewLength = plan.newLength;
              if (plan.wasRounded) {
                infoNote = 'Pediste ${plan.requestedCount} subredes. Como las subredes de igual tamaño solo '
                    'pueden crearse en potencias de 2, se redondeó hacia arriba a ${plan.deliveredCount} '
                    'subredes de /${plan.newLength}.';
              }
              break;
            case _Mode.byHosts:
              final h = _parseRequiredInt(hostsPerSubnetCtrl.text, 'La cantidad de hosts por subred');
              final plan = Ipv4Subnetting.byHostsPerSubnet(base, h);
              v4rows = plan.rows;
              resolvedNewLength = plan.newLength;
              infoNote = 'Para entregar al menos ${plan.requestedHosts} hosts utilizables por subred se necesita /${plan.newLength} '
                  '(${plan.rows.first.hostCount} hosts utilizables reales por subred). '
                  'La red base permite ${plan.deliveredCount} subred(es) de ese tamaño.';
              break;
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subnetting y transición de máscara', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
              'Generaliza la función "Netmask for sub/supernet, move to:" de las calculadoras IP clásicas, '
              'pero sin obligarte a calcular el prefijo destino a mano: puedes pedirlo por prefijo, por '
              'cantidad de subredes o por hosts necesarios por subred.'),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('IPv4')),
              ButtonSegment(value: true, label: Text('IPv6')),
            ],
            selected: {isIpv6},
            onSelectionChanged: (s) {
              setState(() {
                isIpv6 = s.first;
                if (mode == _Mode.byHosts && isIpv6) mode = _Mode.byPrefix;
                if (isIpv6) {
                  addressCtrl.text = '2001:db8:1200::';
                  originalPrefixCtrl.text = '48';
                  newPrefixCtrl.text = '56';
                } else {
                  addressCtrl.text = '192.168.0.1';
                  originalPrefixCtrl.text = '24';
                  newPrefixCtrl.text = '26';
                }
              });
              _calculate();
            },
          ),
          const SizedBox(height: 12),
          Text('¿Cómo quieres calcular las subredes?', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<_Mode>(
            segments: [
              const ButtonSegment(value: _Mode.byPrefix, label: Text('Por prefijo destino (/q)')),
              const ButtonSegment(value: _Mode.byCount, label: Text('Por cantidad de subredes')),
              ButtonSegment(value: _Mode.byHosts, label: const Text('Por hosts por subred'), enabled: !isIpv6),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección / red base', border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: originalPrefixCtrl,
                  decoration: const InputDecoration(labelText: 'Prefijo original /p', border: OutlineInputBorder()),
                ),
              ),
              if (mode == _Mode.byPrefix) ...[
                const Icon(Icons.arrow_forward),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: newPrefixCtrl,
                    decoration: const InputDecoration(labelText: 'Mover a /q', border: OutlineInputBorder()),
                  ),
                ),
              ] else if (mode == _Mode.byCount) ...[
                const Icon(Icons.arrow_forward),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: desiredCountCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad de subredes deseada', border: OutlineInputBorder()),
                  ),
                ),
              ] else ...[
                const Icon(Icons.arrow_forward),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: hostsPerSubnetCtrl,
                    decoration: const InputDecoration(labelText: 'Hosts utilizables por subred', border: OutlineInputBorder()),
                  ),
                ),
              ],
              FilledButton(onPressed: _calculate, child: const Text('Calcular')),
            ],
          ),
          const SizedBox(height: 20),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            ),
          if (infoNote != null)
            Card(
              color: Colors.amber.shade50,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(infoNote!)),
            ),
          if (v4rows != null) _buildIpv4Rows(v4rows!),
          if (v6rows != null) _buildIpv6Rows(v6rows!),
        ],
      ),
    );
  }

  String _titleFor(int rowCount) {
    final isSplit = resolvedNewLength > originalLength;
    final isSuper = resolvedNewLength < originalLength;
    if (isSplit) return 'Subredes tras dividir de /$originalLength a /$resolvedNewLength ($rowCount subredes):';
    if (isSuper) return 'Superred al agregar de /$originalLength a /$resolvedNewLength:';
    return 'Misma red (/$resolvedNewLength):';
  }

  Widget _buildIpv4Rows(List<Ipv4SubnetRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_titleFor(rows.length), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((e) => _ipv4Card(e.key + 1, e.value, rows.length > 1)),
      ],
    );
  }

  Widget _ipv4Card(int index, Ipv4SubnetRow row, bool numbered) {
    final p = row.prefix;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (numbered)
              Text('$index. ${p.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            BitRow(label: 'Network', spans: ipv4BitSpans(row.network.value, p.length, prefixColor: Colors.green), trailing: '${row.network.dotted}/${p.length}'),
            if (row.hostMin != null)
              BitRow(label: 'HostMin', spans: ipv4BitSpans(row.hostMin!.value, p.length, prefixColor: Colors.green), trailing: row.hostMin!.dotted),
            if (row.hostMax != null)
              BitRow(label: 'HostMax', spans: ipv4BitSpans(row.hostMax!.value, p.length, prefixColor: Colors.green), trailing: row.hostMax!.dotted),
            BitRow(label: 'Broadcast', spans: ipv4BitSpans(row.broadcast.value, p.length, prefixColor: Colors.green), trailing: row.broadcast.dotted),
            const SizedBox(height: 4),
            Text('Hosts/Net: ${row.hostCount}   •   ${row.classification.label}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildIpv6Rows(List<Ipv6Prefix> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_titleFor(rows.length), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((e) => _ipv6Card(e.key + 1, e.value, rows.length > 1)),
      ],
    );
  }

  Widget _ipv6Card(int index, Ipv6Prefix p, bool numbered) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (numbered)
              Text('$index. ${p.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Inicio: ${p.networkStart.canonical}'),
            Text('Fin: ${p.networkEnd.canonical}'),
            Text('Direcciones: ${p.totalAddresses}'),
          ],
        ),
      ),
    );
  }
}
