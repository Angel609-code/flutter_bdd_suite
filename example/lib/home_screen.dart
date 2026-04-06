import 'package:flutter/material.dart';

/// Model representing a single employee record.
class Employee {
  final int id;
  final String name;
  final String role;
  final int age;
  final String biography;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.age,
    required this.biography,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? role,
    int? age,
    String? biography,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      age: age ?? this.age,
      biography: biography ?? this.biography,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  int _nextId = 4;

  final List<Employee> _employees = [
    const Employee(
      id: 1,
      name: 'Alice Johnson',
      role: 'Engineer',
      age: 30,
      biography: 'Senior software engineer with 8 years of experience.',
    ),
    const Employee(
      id: 2,
      name: 'Bob Martinez',
      role: 'Designer',
      age: 27,
      biography: 'UX/UI designer passionate about inclusive design.',
    ),
    const Employee(
      id: 3,
      name: 'Carol White',
      role: 'Manager',
      age: 42,
      biography: 'Department manager with a background in agile coaching.',
    ),
  ];

  String _searchQuery = '';

  List<Employee> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    final q = _searchQuery.toLowerCase();
    return _employees
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.role.toLowerCase().contains(q))
        .toList();
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────

  void _openEmployeeDialog({Employee? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final roleCtrl =
        TextEditingController(text: existing?.role ?? '');
    final ageCtrl =
        TextEditingController(text: existing != null ? '${existing.age}' : '');
    final bioCtrl =
        TextEditingController(text: existing?.biography ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Add Employee' : 'Edit Employee',
            key: const Key('employee_dialog_title'),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: const Key('employee_name_field'),
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('employee_role_field'),
                      controller: roleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role / Job Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Role is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('employee_age_field'),
                      controller: ageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Age is required';
                        }
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null) return 'Age must be a number';
                        if (parsed < 18) {
                          return 'Employee must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('employee_bio_field'),
                      controller: bioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Biography / Notes',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('cancel_employee_button'),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('save_employee_button'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final employee = Employee(
                    id: existing?.id ?? _nextId++,
                    name: nameCtrl.text.trim(),
                    role: roleCtrl.text.trim(),
                    age: int.parse(ageCtrl.text.trim()),
                    biography: bioCtrl.text.trim(),
                  );
                  setState(() {
                    if (existing == null) {
                      _employees.add(employee);
                    } else {
                      final idx =
                          _employees.indexWhere((e) => e.id == existing.id);
                      if (idx != -1) _employees[idx] = employee;
                    }
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────

  void _confirmDelete(Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to remove ${employee.name}?',
          key: const Key('delete_confirm_message'),
        ),
        actions: [
          TextButton(
            key: const Key('delete_cancel_button'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('delete_confirm_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _employees.removeWhere((e) => e.id == employee.id);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final employees = _filteredEmployees;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TeamSync — Employee Directory'),
        centerTitle: false,
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
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Welcome banner ──────────────────────────────────────
                    const Text(
                      'Welcome to the Dashboard!',
                      key: Key('dashboard_welcome'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // ── Stats row ───────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            key: const Key('stat_total'),
                            label: 'Total Employees',
                            value: '${_employees.length}',
                            icon: Icons.people,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: _StatCard(
                            key: const Key('stat_roles'),
                            label: 'Unique Roles',
                            value:
                                '${_employees.map((e) => e.role).toSet().length}',
                            icon: Icons.work,
                            color: Colors.teal,
                          ),
                        ),
                        Expanded(
                          child: _StatCard(
                            key: const Key('stat_avg_age'),
                            label: 'Average Age',
                            value: _employees.isEmpty
                                ? '—'
                                : (_employees
                                            .fold<int>(
                                                0, (sum, e) => sum + e.age) /
                                        _employees.length)
                                    .toStringAsFixed(1),
                            icon: Icons.bar_chart,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Search bar ──────────────────────────────────────────
                    TextField(
                      key: const Key('search_field'),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or role…',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),

                    // ── Employee table ──────────────────────────────────────
                    Card(
                      child: employees.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No employees found.',
                                  key: Key('empty_employee_text'),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : LayoutBuilder(
                            builder: (context, constraint) {
                              return Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      constraints: BoxConstraints(minWidth: constraint.maxWidth),
                                      child: DataTable(
                                        key: const Key('employee_table'),
                                        sortAscending: true,
                                        columns: const [
                                          DataColumn(label: Text('ID')),
                                          DataColumn(label: Text('Name')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Age'), numeric: true),
                                          DataColumn(label: Text('Biography')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: List.generate(employees.length, (i) {
                                          final emp = employees[i];
                                          return DataRow(
                                            key: ValueKey('employee_row_${emp.id}'),
                                            cells: [
                                              DataCell(Text('${emp.id}',
                                                  key: Key('emp_id_${emp.id}'))),
                                              DataCell(Text(emp.name,
                                                  key: Key('emp_name_${emp.id}'))),
                                              DataCell(Text(emp.role,
                                                  key: Key('emp_role_${emp.id}'))),
                                              DataCell(Text('${emp.age}',
                                                  key: Key('emp_age_${emp.id}'))),
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(
                                                      maxWidth: 200),
                                                  child: Text(
                                                    emp.biography,
                                                    key: Key('emp_bio_${emp.id}'),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      key: Key('edit_employee_$i'),
                                                      icon: const Icon(Icons.edit,
                                                          size: 18),
                                                      tooltip: 'Edit',
                                                      onPressed: () =>
                                                          _openEmployeeDialog(
                                                              existing: emp),
                                                    ),
                                                    IconButton(
                                                      key: Key('delete_employee_$i'),
                                                      icon: const Icon(Icons.delete,
                                                          size: 18,
                                                          color: Colors.red),
                                                      tooltip: 'Delete',
                                                      onPressed: () =>
                                                          _confirmDelete(emp),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                              );
                            }
                          ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_employee_fab'),
        onPressed: () => _openEmployeeDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}

// ── Small stat card widget ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
