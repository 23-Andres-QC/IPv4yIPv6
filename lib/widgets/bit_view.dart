import 'package:flutter/material.dart';

/// Construye los spans coloreados de los 32 bits de una IPv4, agrupados en
/// octetos separados por '.', resaltando los bits de prefijo/máscara.
List<InlineSpan> ipv4BitSpans(int value, int prefixLength, {required Color prefixColor, Color hostColor = Colors.grey}) {
  final bits = value.toRadixString(2).padLeft(32, '0');
  final spans = <InlineSpan>[];
  for (var i = 0; i < 32; i++) {
    final isPrefix = i < prefixLength;
    spans.add(TextSpan(
      text: bits[i],
      style: TextStyle(
        color: isPrefix ? prefixColor : hostColor,
        fontWeight: isPrefix ? FontWeight.bold : FontWeight.normal,
      ),
    ));
    if (i % 8 == 7 && i != 31) {
      spans.add(const TextSpan(text: '.', style: TextStyle(color: Colors.black54)));
    }
  }
  return spans;
}

/// Equivalente para IPv6: 128 bits agrupados en 16 grupos de 8 bits
/// separados por '.', con los grupos de 16 bits remarcados cada 16 bits con
/// un espacio para facilitar lectura.
List<InlineSpan> ipv6BitSpans(BigInt value, int prefixLength, {required Color prefixColor, Color hostColor = Colors.grey}) {
  final bits = value.toRadixString(2).padLeft(128, '0');
  final spans = <InlineSpan>[];
  for (var i = 0; i < 128; i++) {
    final isPrefix = i < prefixLength;
    spans.add(TextSpan(
      text: bits[i],
      style: TextStyle(
        color: isPrefix ? prefixColor : hostColor,
        fontWeight: isPrefix ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    ));
    if (i % 16 == 15 && i != 127) {
      spans.add(const TextSpan(text: ' ', style: TextStyle(color: Colors.black54)));
    }
  }
  return spans;
}

class BitRow extends StatelessWidget {
  final String label;
  final List<InlineSpan> spans;
  final String? trailing;
  const BitRow({super.key, required this.label, required this.spans, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText.rich(
              TextSpan(style: const TextStyle(fontFamily: 'monospace', fontSize: 13), children: spans),
            ),
          ),
          if (trailing != null) Text(trailing!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
