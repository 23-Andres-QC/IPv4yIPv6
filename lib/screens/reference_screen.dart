import 'package:flutter/material.dart';
import '../app_localization.dart';
import '../core/reference_data.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Referencia normativa'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'RFC que sustentan los cálculos y reglas de validación de este sistema.',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: DataTable(
              columns: [
                const DataColumn(label: Text('RFC')),
                DataColumn(label: Text(context.t('Tema'))),
                DataColumn(label: Text(context.t('Por qué importa'))),
              ],
              rows: rfcReferenceTable
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r.rfc,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(r.topic)),
                        DataCell(SizedBox(width: 420, child: Text(r.why))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
