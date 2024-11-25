import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webweb/ui/materials_page.dart';

class MasterMaintenanceScreen extends StatefulWidget {
  const MasterMaintenanceScreen({super.key});

  @override
  State<MasterMaintenanceScreen> createState() =>
      _MasterMaintenanceScreenState();
}

class _MasterMaintenanceScreenState extends State<MasterMaintenanceScreen> {
  List<List<dynamic>> _csvData = [];
  List<Map<String, dynamic>> _errors = [];
  double _progress = 0.0;
  bool _isProcessing = false;
  bool _hasErrors = false; // Flag to check if there are errors

  Future<void> parseCSVBytes() async {
    // Create an input element for file picking
    final FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = '.csv'; // Specify file type (CSV)

    // Show file picker
    uploadInput.click();

    // Listen for when a file is selected
    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        print('No file selected.');
        return;
      }

      final file = files.first;

      // Use FileReader to read the file as bytes
      final reader = FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) async {
        final fileBytes = reader.result as List<int>;

        try {
          final decodedContent = decodeShiftJIS(Uint8List.fromList(fileBytes));
          final csvData = const CsvToListConverter().convert(decodedContent);
          _csvData = csvData;
          _errors = await validateRows(_csvData);
          _hasErrors = _errors.isNotEmpty; // Check if there are errors
          setState(() {});
        } catch (e) {
          print("Error decoding file: $e");
        }
      });
    });
  }

  _refresh() {
    _isRefresh = true;
    Future.delayed(const Duration(seconds: 2), () {
      _isRefresh = false;
      setState(() {});
    });
  }

  int materialNameIndex1 = -1;
  int materialNameIndex2 = -1;
  int standardUnitIndex = -1;
  int standardUnitCostIndex = -1;

  bool _isRefresh = false;

  String decodeShiftJIS(Uint8List bytes) {
    // Check for TextDecoder availability
    final textDecoder = js_util.callConstructor(
      js_util.getProperty(js_util.globalThis, 'TextDecoder'),
      ['shift_jis'],
    );

    // Create Uint8Array for the bytes
    final jsUint8Array = js_util.callConstructor(
      js_util.getProperty(js_util.globalThis, 'Uint8Array'),
      [bytes],
    );

    // Decode using TextDecoder
    return js_util.callMethod(textDecoder, 'decode', [jsUint8Array]) as String;
  }

  Future<List<Map<String, dynamic>>> validateRows(
      List<List<dynamic>> rows) async {
    final errors = <Map<String, dynamic>>[];

    Set<String> materialNames2 =
        {}; // To track duplicate material names in 品目名2
    Set<String> standardUnits = {}; // To track duplicate standard units
    Set<String> standardUnitCosts =
        {}; // To track duplicate standard unit costs

    // Identify column indices based on the first row

    if (rows.isNotEmpty) {
      for (int i = 0; i < rows[0].length; i++) {
        String header = rows[0][i].toString().trim();
        if (header == "品目名1") {
          materialNameIndex1 = i;
        } else if (header == "品目名2") {
          materialNameIndex2 = i;
        } else if (header == "標準単位") {
          standardUnitIndex = i;
        } else if (header == "標準単価") {
          standardUnitCostIndex = i;
        }
      }
    }

    // Validate each row based on the identified columns
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      // Skip rows that don't have the required number of columns
      if (row.length < 4) {
        errors.add({
          'row': i + 1,
          'message':
              'Row must have at least 4 columns (品目名1, 品目名2, 標準単位, 標準単価)',
        });
        continue;
      }

      // Validate material_name_1 (品目名1)
      if (materialNameIndex1 >= 0 &&
          (row[materialNameIndex1] == null ||
              row[materialNameIndex1].toString().trim().isEmpty)) {
        errors.add({
          'row': i + 1,
          'column': '品目名1',
          'message': 'Material name 1 cannot be empty',
        });
      }

      // Validate material_name_2 (品目名2)
      if (materialNameIndex2 >= 0) {
        final materialName1 = row[materialNameIndex1]?.toString().trim() ?? '';
        final materialName2 = row[materialNameIndex2]?.toString().trim() ?? '';

        // Check if material_name_2 is the same as material_name_1 on the same row
        if (materialName2.isNotEmpty && materialName2 == materialName1) {
          errors.add({
            'row': i + 1,
            'column': '品目名2',
            'message':
                'Material name 2 cannot be the same as material name 1 on the same row',
          });
        }

        // Check for duplicate material names in 品目名2
        if (materialName2.isNotEmpty &&
            materialNames2.contains(materialName2)) {
          errors.add({
            'row': i + 1,
            'column': '品目名2',
            'message': 'Duplicate material name 2 found',
          });
        } else if (materialName2.isNotEmpty) {
          materialNames2.add(materialName2);
        }
      }
    }

    return errors;
  }

  Future<void> insertData(List<List<dynamic>> data) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Identify column indices based on the first row
    if (data.isNotEmpty) {
      for (int i = 0; i < data[0].length; i++) {
        String header = data[0][i].toString().trim();
        if (header == "品目名1") {
          materialNameIndex1 = i;
        } else if (header == "標準単位") {
          standardUnitIndex = i;
        } else if (header == "標準単価") {
          standardUnitCostIndex = i;
        }
      }
    }

    final errors = await validateRows(data);

    if (errors.isNotEmpty) {
      print('Validation failed: $errors');
      return;
    }

    // Proceed with data insertion after validation
    for (var row in data) {
      if (row.length >= 4) {
        final materialName = row[materialNameIndex1];
        final standardUnit = row[standardUnitIndex];
        final standardUnitCost =
            double.tryParse(row[standardUnitCostIndex].toString()) ?? 0.0;

        if (materialName != null && materialName.toString().trim().isNotEmpty) {
          final docRef = firestore.collection('materials').doc();
          batch.set(docRef, {
            'created_at': FieldValue.serverTimestamp(),
            'created_by': 'csv',
            'material_name': materialName,
            'standard_unit': standardUnit,
            'standard_unit_cost': standardUnitCost,
            'updated_at': FieldValue.serverTimestamp(),
            'updated_by': 'csv',
          });
        } else {
          print(
              'Error: Material name cannot be empty at row ${data.indexOf(row) + 1}');
        }
      } else {
        print(
            'Error: Row ${data.indexOf(row) + 1} does not have enough columns');
      }
    }

    try {
      await batch.commit();
      print('Data inserted successfully.');
    } catch (e) {
      print('Error inserting data: $e');
    }
  }

  Future<void> handleDataUpload() async {
    if (_hasErrors) {
      // Do not delete Firestore data if there are errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix the errors before uploading.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Delete existing data
    // await deleteAllMaterials();

    // Insert new data
    final rowsToUpload = _csvData.sublist(1); // Exclude header row
    for (int i = 0; i < rowsToUpload.length; i++) {
      await insertData([rowsToUpload[i]]);
      setState(() {
        _progress = ((i + 1) / rowsToUpload.length) * 100;
      });
    }

    setState(() {
      _isProcessing = false;
      _progress = 0.0;
    });
    _refresh();
  }

  Future<void> deleteAllMaterials() async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore.collection('materials').get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _isRefresh
            ? const Center(child: CircularProgressIndicator())
            : MaterialsPage(
                handleDataUpload: handleDataUpload,
                parseCSVBytes: parseCSVBytes,
                csvData: _csvData,
                errors: _errors,
                progress: _progress,
                isProcessing: _isProcessing,
                hasErrors: _hasErrors));
  }
}
