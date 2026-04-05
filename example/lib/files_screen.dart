import 'package:flutter/material.dart';

/// Parses a raw CSV string into a list of rows (each row is a list of cells).
List<List<String>> parseCsv(String raw) {
  final lines = raw.trim().split('\n');
  return lines.map((line) {
    return line.split(',').map((cell) => cell.trim()).toList();
  }).toList();
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  // Simulated in-memory CSV data (would come from a real file picker in prod)
  static const String _sampleCsvContent = '''name,role,age,email
Alice Johnson,Engineer,30,alice@teamsync.io
Bob Martinez,Designer,27,bob@teamsync.io
Carol White,Manager,42,carol@teamsync.io
David Kim,Analyst,35,david@teamsync.io''';

  final List<Map<String, String>> _importedFiles = [];
  String _statusMessage = 'No files imported yet.';
  List<List<String>>? _parsedCsvRows;
  String _rawCsvPreview = '';
  bool _showRawCsv = false;

  void _importCsv() {
    final filename =
        'employees_${DateTime.now().millisecondsSinceEpoch}.csv';
    final parsed = parseCsv(_sampleCsvContent);
    setState(() {
      _importedFiles.add({
        'name': filename,
        'content': _sampleCsvContent,
      });
      _parsedCsvRows = parsed;
      _rawCsvPreview = _sampleCsvContent;
      _statusMessage = 'CSV file imported successfully.';
    });
  }

  void _exportCsv() {
    setState(() {
      _statusMessage = 'Data exported to CSV successfully.';
    });
  }

  void _toggleRaw() {
    setState(() => _showRawCsv = !_showRawCsv);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsedCsvRows;
    final hasHeaders = parsed != null && parsed.isNotEmpty;
    final headers = hasHeaders ? parsed.first : <String>[];
    final dataRows = hasHeaders && parsed.length > 1
        ? parsed.sublist(1)
        : <List<String>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('File Management')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Action card ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusMessage,
                          key: const Key('file_status_message'),
                          style: TextStyle(
                            color: _statusMessage.contains('successfully')
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              key: const Key('import_csv_button'),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Import CSV'),
                              onPressed: _importCsv,
                            ),
                            ElevatedButton.icon(
                              key: const Key('export_csv_button'),
                              icon: const Icon(Icons.download),
                              label: const Text('Export CSV'),
                              onPressed: _exportCsv,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── CSV preview ──────────────────────────────────────────────
                if (parsed != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CSV Content',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        key: const Key('toggle_raw_button'),
                        icon: Icon(
                            _showRawCsv ? Icons.table_chart : Icons.code),
                        label:
                            Text(_showRawCsv ? 'Table View' : 'Raw View'),
                        onPressed: _toggleRaw,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_showRawCsv)
                    Card(
                      color: Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _rawCsvPreview,
                          key: const Key('csv_raw_content'),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          key: const Key('csv_content_table'),
                          headingRowColor: WidgetStateProperty.all(
                              Colors.indigo.shade50),
                          columns: headers
                              .map((h) => DataColumn(
                                  label: Text(h,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))))
                              .toList(),
                          rows: List.generate(dataRows.length, (i) {
                            final row = dataRows[i];
                            return DataRow(
                              key: ValueKey('csv_row_$i'),
                              cells: List.generate(
                                row.length,
                                (j) => DataCell(
                                  Text(row[j], key: Key('csv_cell_${i}_$j')),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // ── Imported files list ──────────────────────────────────────
                const Text(
                  'Imported Files:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _importedFiles.isEmpty
                      ? const Center(
                          child: Text('Empty list',
                              key: Key('empty_files_text')))
                      : ListView.builder(
                          key: const Key('imported_files_list'),
                          itemCount: _importedFiles.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                key: Key('file_item_$index'),
                                leading:
                                    const Icon(Icons.insert_drive_file),
                                title: Text(
                                    _importedFiles[index]['name'] ?? ''),
                                subtitle: Text(
                                  '${parseCsv(_importedFiles[index]['content']!).length - 1} data rows',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
