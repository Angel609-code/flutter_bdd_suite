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
        title: const Text('Home'),
        actions: [
          IconButton(
            key: const Key('settings_action'),
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Welcome to the Dashboard!', style: TextStyle(fontSize: 20)),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                key: const Key('item_list'),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: Key('list_item_$index'),
                    title: Text('Item $index'),
                    subtitle: Text('Description for item $index'),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
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
                    DataCell(Text(user['status'])),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_user_fab'),
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
