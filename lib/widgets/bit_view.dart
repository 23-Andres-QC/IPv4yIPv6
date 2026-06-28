import 'package:flutter/material.dart';

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
  final String sublabel;
  final List<InlineSpan> spans;
  final String? trailing;

  const BitRow({
    super.key,
    required this.label,
    this.sublabel = '',
    required this.spans,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                if (sublabel.isNotEmpty)
                  Text(sublabel, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ],
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
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                trailing!,
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
