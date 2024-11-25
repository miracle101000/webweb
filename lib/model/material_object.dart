import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialObject {
  final DateTime createdAt;
  final String createdBy;
  final String materialName;
  final String standardUnit;
  final double standardUnitCost;
  final DateTime updatedAt;
  final String updatedBy;

  MaterialObject({
    required this.createdAt,
    required this.createdBy,
    required this.materialName,
    required this.standardUnit,
    required this.standardUnitCost,
    required this.updatedAt,
    required this.updatedBy,
  });
  // Create a Material object from JSON
  factory MaterialObject.fromJson(Map<String, dynamic> json) {
    return MaterialObject(
      materialName: json['material_name'] ?? '', // 品目名
      standardUnit: json['standard_unit'] ?? '', // 標準単位
      standardUnitCost:
          double.tryParse(json['standard_unit_cost'].toString()) ?? 0.0, // 標準単価
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(), // created_at
      createdBy: json['created_by'] ?? '', // created_by
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate() ??
          DateTime.now(), // updated_at
      updatedBy: json['updated_by'] ?? '', // updated_by
    );
  }
}
