// client/lib/features/debug/presentation/widgets/table_view_widget.dart
import 'package:flutter/material.dart';

class TableViewWidget extends StatelessWidget {
  final String tableName;
  final List<Map<String, dynamic>> data;

  const TableViewWidget({
    super.key,
    required this.tableName,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('No data found for table "$tableName"'),
      );
    }

    // Extract all unique column names
    final Set<String> allColumns = {};
    for (var row in data) {
      allColumns.addAll(row.keys);
    }
    final columns = allColumns.toList();
    columns.sort(); // Sort columns alphabetically for consistency

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns
              .map((col) => DataColumn(
                    label: Text(
                      col,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: data
              .map(
                (row) => DataRow(
                  cells: columns
                      .map(
                        (col) => DataCell(
                          Text(row[col]?.toString() ?? 'NULL'),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
