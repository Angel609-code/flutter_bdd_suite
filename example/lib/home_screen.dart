import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _users = [
    {'id': 1, 'name': 'John Doe', 'status': 'Active'},
    {'id': 2, 'name': 'Jane Smith', 'status': 'Inactive'},
    {'id': 3, 'name': 'Bob Johnson', 'status': 'Active'},
  ];

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: const Text('Do you want to add a new user?'),
          actions: [
            TextButton(
              key: const Key('dialog_cancel'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('dialog_confirm'),
              onPressed: () {
                setState(() {
                  _users.add({
                    'id': _users.length + 1,
                    'name': 'New User',
                    'status': 'Active'
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dashboard'),
        actions: [
          IconButton(
            key: const Key('files_action'),
            icon: const Icon(Icons.folder),
            onPressed: () => Navigator.pushNamed(context, '/files'),
            tooltip: 'Files',
          ),
          IconButton(
            key: const Key('dialogs_action'),
            icon: const Icon(Icons.chat_bubble),
            onPressed: () => Navigator.pushNamed(context, '/dialogs'),
            tooltip: 'Dialogs',
          ),
          IconButton(
            key: const Key('settings_action'),
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Welcome to the Dashboard!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Recent Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              key: const Key('item_list'),
                              itemCount: 20,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  key: Key('list_item_$index'),
                                  leading: const Icon(Icons.article),
                                  title: Text('Item $index'),
                                  subtitle: Text('Description for item $index'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DataTable(
                                key: const Key('user_table'),
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Status')),
                                ],
                                rows: _users.map((user) {
                                  return DataRow(cells: [
                                    DataCell(Text(user['id'].toString())),
                                    DataCell(Text(user['name'])),
                                    DataCell(
                                      Chip(
                                        label: Text(user['status']),
                                        backgroundColor: user['status'] == 'Active' ? Colors.green.shade100 : Colors.red.shade100,
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_user_fab'),
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}
