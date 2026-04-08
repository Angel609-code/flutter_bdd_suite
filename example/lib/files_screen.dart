import 'package:flutter/material.dart';

/// Parses a raw CSV string into a list of rows (each row is a list of cells).
List<List<String>> parseCsv(String raw) {
  final lines = raw.trim().split('\n');
  return lines.map((line) {
    return line.split(',').map((cell) => cell.trim()).toList();
  }).toList();
}

/// A screen to view and manage imported CSV files.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  static const String _sampleCsvContent = '''name,role,age,email
Alice Johnson,Engineer,30,alice@teamsync.io
Bob Martinez,Designer,27,bob@teamsync.io
Carol White,Manager,42,carol@teamsync.io
David Kim,Analyst,35,david@teamsync.io''';

  final ScrollController _scrollController = ScrollController();

  final List<_ImportedFile> _files = [];
  List<List<String>>? _parsed;
  bool _showRaw = false;
  String _status = 'No files imported yet.';

  void _importCsv() {
    final parsed = parseCsv(_sampleCsvContent);

    setState(() {
      _files.add(_ImportedFile(
        name: 'employees_${DateTime.now().millisecondsSinceEpoch}.csv',
        content: _sampleCsvContent,
        rowCount: parsed.length - 1,
      ));

      _parsed = parsed;
      _status = 'CSV file imported successfully.';
    });
  }

  void _exportCsv() {
    setState(() {
      _status = 'Data exported to CSV successfully.';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Management')),
      body: ListView(
        key: const Key('files_screen_listview'),
        children: [
          _ActionCard(
            status: _status,
            onImport: _importCsv,
            onExport: _exportCsv,
          ),

          const SizedBox(height: 16),

          if (_parsed != null)
            _CsvPreview(
              parsed: _parsed!,
              showRaw: _showRaw,
              onToggle: () => setState(() => _showRaw = !_showRaw),
              controller: _scrollController,
            ),

          const SizedBox(height: 16),

          _FilesList(files: _files),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String status;
  final VoidCallback onImport;
  final VoidCallback onExport;

  const _ActionCard({
    required this.status,
    required this.onImport,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = status.contains('successfully');

    return ListContainer(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                key: const Key('file_status_message'),
                status,
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    key: const Key('import_csv_button'),
                    onPressed: onImport,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import CSV'),
                  ),
                  ElevatedButton.icon(
                    key: const Key('export_csv_button'),
                    onPressed: onExport,
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _CsvPreview extends StatelessWidget {
  final List<List<String>> parsed;
  final bool showRaw;
  final VoidCallback onToggle;
  final ScrollController controller;

  const _CsvPreview({
    required this.parsed,
    required this.showRaw,
    required this.onToggle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final headers = parsed.first;
    final rows = parsed.length > 1 ? parsed.sublist(1) : [];

    return Column(
      children: [
        ListContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CSV Content'),
              TextButton.icon(
                key: const Key('toggle_raw_button'),
                icon: Icon(showRaw ? Icons.table_chart : Icons.code),
                label: Text(showRaw ? 'Table View' : 'Raw View'),
                onPressed: onToggle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (showRaw)
          ListContainer(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  key: const Key('csv_raw_content'),
                  parsed.map((e) => e.join(',')).join('\n'),
                ),
              ),
            ),
          )
        else
          ListContainer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  controller: controller,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        key: const Key('csv_content_table'),
                        columns: headers
                            .map((h) => DataColumn(label: Text(h)))
                            .toList(),
                        rows: List.generate(rows.length, (rowIdx) {
                          final row = rows[rowIdx];
                          return DataRow(
                            key: ValueKey('csv_row_$rowIdx'),
                            cells: List.generate(row.length, (cellIdx) {
                              return DataCell(
                                Text(
                                  row[cellIdx],
                                  key: Key('csv_cell_${rowIdx}_$cellIdx'),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FilesList extends StatelessWidget {
  final List<_ImportedFile> files;

  const _FilesList({required this.files});

  @override
  Widget build(BuildContext context) {
    return ListContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Imported Files'),
          const SizedBox(height: 8),
          if (files.isEmpty)
            const Text(key: Key('empty_files_text'), 'Empty list')
          else
            Wrap(
              key: const Key('imported_files_list'),
              children: List.generate(files.length, (i) {
                final f = files[i];
                return Card(
                  child: ListTile(
                    key: Key('file_item_$i'),
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(f.name),
                    subtitle: Text('${f.rowCount} data rows'),
                  ),
                );
              }),
            )
        ],
      ),
    );
  }
}

class ListContainer extends StatelessWidget {
  final Widget child;

  const ListContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: child,
        ),
      ),
    );
  }
}

class _ImportedFile {
  final String name;
  final String content;
  final int rowCount;

  _ImportedFile({
    required this.name,
    required this.content,
    required this.rowCount,
  });
}