import 'package:flutter/material.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final List<String> _importedFiles = [];
  String _statusMessage = 'No files imported yet.';

  void _importCsv() {
    setState(() {
      _importedFiles.add('data_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      _statusMessage = 'CSV file imported successfully.';
    });
  }

  void _exportCsv() {
    setState(() {
      _statusMessage = 'Data exported to CSV successfully.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Management')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(_statusMessage, key: const Key('file_status_message')),
                        const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                const Text('Imported Files:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: _importedFiles.isEmpty
                      ? const Center(child: Text('Empty list', key: Key('empty_files_text')))
                      : ListView.builder(
                          key: const Key('imported_files_list'),
                          itemCount: _importedFiles.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                key: Key('file_item_$index'),
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(_importedFiles[index]),
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
