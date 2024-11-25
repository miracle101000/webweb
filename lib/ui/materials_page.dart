import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webweb/model/material_object.dart';

import '../custom_data_table.dart';

class MaterialsPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<Map<String, dynamic>> errors;
  final double progress;
  final bool isProcessing;
  final bool hasErrors;
  final void Function() handleDataUpload;
  final void Function() parseCSVBytes;
  const MaterialsPage(
      {super.key,
      required this.csvData,
      required this.errors,
      required this.hasErrors,
      required this.isProcessing,
      required this.handleDataUpload,
      required this.parseCSVBytes,
      required this.progress});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final List<Map<String, dynamic>> _materials = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  final List<String> _errorMessages = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query = _firestore
        .collection('materials')
        .orderBy('material_name')
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      // _materials.clear();
      _materials.addAll(
          querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
    }

    if (querySnapshot.docs.length < _pageSize) {
      _hasMore = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: widget.parseCSVBytes,
                  child: const Text('Upload CSV'),
                ),
                if (widget.csvData.isNotEmpty && !widget.hasErrors)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed:
                          widget.isProcessing ? null : widget.handleDataUpload,
                      child: widget.isProcessing
                          ? Text(
                              'Processing... (${widget.progress.toStringAsFixed(0)}%)')
                          : const Text('Upload Data to Firestore'),
                    ),
                  ),
              ],
            ),
            if (widget.errors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('Errors: ', style: TextStyle(color: Colors.red)),
                    ...widget.errors.map((e) => Text(
                          'Row ${e['row']}, Column ${e['column']}: ${e['message']}',
                          style: const TextStyle(color: Colors.red),
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (_errorMessages.isNotEmpty) const SizedBox(height: 20),
            if (_errorMessages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 30,
                  child: Row(
                    children: _errorMessages
                        .map((e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                e,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            PaginatedDataTable(
              header: const Text('Master Maintenance'),
              columns: const [
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Material Name')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Standard Unit')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Standard Unit Cost')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Created At')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Created By')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Updated At')),
                DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Updated By'))
              ],
              onPageChanged: (value) {
                _loadMaterials();
              },
              source: CustomDataTableSource(
                  items: _materials
                      .map((_) => MaterialObject.fromJson(_))
                      .toList()),
            ),
          ],
        ),
      ),
    );
  }
}
