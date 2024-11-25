import 'package:flutter/material.dart';
import '../model/material_object.dart';

class CustomDataTableSource extends DataTableSource {
  final List<MaterialObject> items;
  int selectedCount = 0;

  CustomDataTableSource({required this.items});

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;

    final item = items[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(item.materialName.toString())), // Material Name
        DataCell(Text(item.standardUnit.toString())), // Standard Unit
        DataCell(Text((item.standardUnitCost.toString())
            .toString())), // Standard Unit Cost
        DataCell(Text(item.createdAt.toString())), // Created At
        DataCell(Text(item.createdBy.toString())), // Created By
        DataCell(Text((item.updatedAt.toString()))), // Updated At
        DataCell(Text(item.updatedBy.toString())),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => selectedCount;
}
