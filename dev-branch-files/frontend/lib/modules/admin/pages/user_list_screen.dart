import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/router/route_names.dart';
import '../utils/file_downloader.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../erp_repository.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  bool _isTableView = true;
  bool _hasInitializedQueryParam = false;
  int _currentPage = 1;
  int _pageSize = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedQueryParam) {
      final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
      if (roleParam == 'faculty') {
        _selectedRole = 'Faculty';
      } else if (roleParam == 'student') {
        _selectedRole = 'Student';
      }
      _hasInitializedQueryParam = true;
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _formRole = 'Student';
  String _formDept = 'Computer Science';
  String _formStatus = 'Active';

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showAddUserModal() {
    _nameController.clear();
    _emailController.clear();
    _formRole = 'Student';
    _formDept = 'Computer Science';
    _formStatus = 'Active';
    var isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0052CC), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Onboard New User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text('Create user account & assign permissions', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Dr. Suresh Kumar',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0052CC)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'suresh.kumar@ksrce.ac.in',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0052CC)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email is required';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _formRole,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'System Role',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              items: ['Student', 'Faculty', 'Department HOD', 'Registrar', 'Admin'].map((role) {
                                return DropdownMenuItem(value: role, child: Text(role));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => _formRole = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _formStatus,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Initial Status',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              items: ['Active', 'Pending', 'Inactive'].map((status) {
                                return DropdownMenuItem(value: status, child: Text(status));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => _formStatus = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _formDept,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Associated Department',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: ['Computer Science', 'Information Technology', 'Electronics & Comm.', 'Mechanical Engg.', 'Civil Engg.', 'Administration'].map((dept) {
                          return DropdownMenuItem(value: dept, child: Text(dept, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _formDept = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Onboard User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setModalState(() => isSubmitting = true);

                                    final messenger = ScaffoldMessenger.maybeOf(context);
                                    final newUser = UserModel(
                                      id: 'USR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      role: _formRole,
                                      department: _formDept,
                                      node: _formStatus == 'Active' ? 'Active Node' : 'Inactive Node',
                                      status: _formStatus,
                                    );

                                    await ref.read(usersProvider.notifier).addUser(newUser);

                                    if (context.mounted) Navigator.of(context).pop();

                                    if (messenger != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('User "${newUser.name}" onboarded and saved to database!'),
                                          backgroundColor: const Color(0xFF16A34A),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  void _showQuickEditModal(UserModel user) {
    final editFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.contactNumber ?? '');
    final empIdCtrl = TextEditingController(text: user.isStudent ? (user.rollNumber ?? '') : (user.employeeId ?? user.id));
    var selectedRole = user.role;
    var selectedDept = user.department;
    var selectedStatus = user.status;

    final rolesList = ['Student', 'Faculty', 'Department HOD', 'Registrar', 'Admin'];
    final statusList = ['Active', 'Pending', 'Inactive'];
    final deptList = ['Computer Science', 'Information Technology', 'Electronics & Comm.', 'Mechanical Engg.', 'Civil Engg.', 'Administration', 'CSE', 'ECE', 'IT', 'MECH', 'CIVIL'];

    if (!rolesList.contains(selectedRole)) rolesList.add(selectedRole);
    if (!statusList.contains(selectedStatus)) statusList.add(selectedStatus);
    if (!deptList.contains(selectedDept)) deptList.add(selectedDept);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: editFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Color(0xFF0052CC), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Edit User — ${user.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    Text('ID: ${user.id} (${user.role})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0052CC)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0052CC)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Contact Phone',
                                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0052CC)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedRole,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'System Role',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: rolesList.map((role) {
                                  return DropdownMenuItem(value: role, child: Text(role));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedRole = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: statusList.map((st) {
                                  return DropdownMenuItem(value: st, child: Text(st));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedDept,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Department',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: deptList.map((dept) {
                                  return DropdownMenuItem(value: dept, child: Text(dept, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedDept = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: empIdCtrl,
                                decoration: InputDecoration(
                                  labelText: selectedRole == 'Student' ? 'Roll Number' : 'Staff / Employee ID',
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0052CC)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0052CC)),
                              label: const Text('Edit All Details (Full Editor)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go('${RouteNames.users}/${user.id}/edit');
                              },
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0052CC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    if (editFormKey.currentState!.validate()) {
                                      final updatedUser = user.copyWith(
                                        name: nameCtrl.text.trim(),
                                        email: emailCtrl.text.trim(),
                                        contactNumber: phoneCtrl.text.trim(),
                                        role: selectedRole,
                                        department: selectedDept,
                                        status: selectedStatus,
                                        employeeId: selectedRole != 'Student' ? empIdCtrl.text.trim() : null,
                                        rollNumber: selectedRole == 'Student' ? empIdCtrl.text.trim() : null,
                                      );
                                      ref.read(usersProvider.notifier).updateUser(updatedUser);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('User "${updatedUser.name}" updated successfully.'),
                                          backgroundColor: const Color(0xFF16A34A),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmationDialog(
          title: 'Delete User Account — ${user.name}',
          content: 'You are about to permanently delete this user account.\n\nUser: ${user.name}\nEmail: ${user.email}\nRole: ${user.role} | Department: ${user.department}',
          confirmLabel: 'Yes, Delete Account',
          cancelLabel: 'Cancel',
          type: ConfirmationType.delete,
          verifyText: user.name,
          verifyHint: 'Type "${user.name}" to confirm deletion:',
          onConfirm: () {
            ref.read(usersProvider.notifier).deleteUser(user.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User "${user.name}" permanently deleted.'),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
    );
  }

  Widget _buildPaginationBar(int totalCount, int totalPages, int safePage) {
    final startItem = totalCount == 0 ? 0 : (safePage - 1) * _pageSize + 1;
    final endItem = (safePage * _pageSize).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          if (isSmall) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Rows: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        DropdownButton<int>(
                          value: _pageSize,
                          underline: const SizedBox(),
                          items: [5, 10, 25, 50, 100].map((size) => DropdownMenuItem<int>(
                              value: size,
                              child: Text('$size', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _pageSize = val;
                                _currentPage = 1;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Text(
                      '$startItem-$endItem of $totalCount',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: safePage > 1
                          ? () => setState(() => _currentPage = safePage - 1)
                          : null,
                    ),
                    Text('Page $safePage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: safePage < totalPages
                          ? () => setState(() => _currentPage = safePage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Rows per page: ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _pageSize,
                    underline: const SizedBox(),
                    items: [5, 10, 25, 50, 100].map((size) => DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _pageSize = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Showing $startItem - $endItem of $totalCount accounts',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: safePage > 1
                        ? () => setState(() => _currentPage = safePage - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Page $safePage of $totalPages', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: safePage < totalPages
                        ? () => setState(() => _currentPage = safePage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final usersNotifier = ref.watch(usersProvider.notifier);

    final filteredUsers = users.where((u) {
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.contactNumber ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'All' || u.role == _selectedRole;
      final matchesStatus = _selectedStatus == 'All' || u.status == _selectedStatus;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    final facultyCount = users.where((u) => u.role == 'Faculty' || u.role == 'Department HOD').length;
    final studentCount = users.where((u) => u.role == 'Student').length;

    final totalPages = (filteredUsers.length / _pageSize).ceil().clamp(1, 9999);
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, filteredUsers.length);
    final paginatedUsers = filteredUsers.isEmpty ? <UserModel>[] : filteredUsers.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final isNarrow = constraints.maxWidth < 480;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 10 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title Header & Actions (Ultra Compact on Mobile)
                if (isMobile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('Manage accounts & roles', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            padding: EdgeInsets.zero,
                            tooltip: 'Refresh DB',
                            icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF0052CC)),
                            onPressed: usersNotifier.loadUsersFromSupabase,
                          ),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            padding: EdgeInsets.zero,
                            tooltip: 'Export CSV',
                            icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF0052CC)),
                            onPressed: () {
                              final buffer = StringBuffer();
                              buffer.writeln('ID,Name,Email,Role,Department,Status');
                              for (final u in filteredUsers) {
                                buffer.writeln('${u.id},"${u.name}",${u.email},${u.role},${u.department},${u.status}');
                              }
                              final bytes = utf8.encode(buffer.toString());
                              FileDownloader.downloadFile(bytes, 'users_directory_export.csv');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User directory exported successfully!'), backgroundColor: Color(0xFF16A34A)),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: _showAddUserModal,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add User', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),

                        ],
                      ),
                    ],
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 14,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management Console',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage total institutional accounts, role allocations, profile updates, and active statuses from master ERP',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: usersNotifier.loadUsersFromSupabase,
                            icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF0052CC)),
                            label: const Text('Refresh DB', style: TextStyle(color: Color(0xFF0052CC))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final buffer = StringBuffer();
                              buffer.writeln('ID,Name,Email,Role,Department,Status');
                              for (final u in filteredUsers) {
                                buffer.writeln('${u.id},"${u.name}",${u.email},${u.role},${u.department},${u.status}');
                              }
                              final bytes = utf8.encode(buffer.toString());
                              FileDownloader.downloadFile(bytes, 'users_directory_export.csv');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User directory exported successfully!'), backgroundColor: Color(0xFF16A34A)),
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF0052CC)),
                            label: const Text('Export CSV', style: TextStyle(color: Color(0xFF0052CC))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddUserModal,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add New User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? 10 : 20),

                // Supabase Error State Alert
                if (usersNotifier.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Database Connection Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 12)),
                              Text(usersNotifier.errorMessage!, style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: usersNotifier.loadUsersFromSupabase,
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Retry', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Integrated Search & Quick Filter Hub
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Filter Pills Header Bar
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 8 : 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRoleFilterChip('All', 'All (${users.length})', Icons.people_alt_rounded),
                              const SizedBox(width: 6),
                              _buildRoleFilterChip('Student', 'Students ($studentCount)', Icons.school_rounded),
                              const SizedBox(width: 6),
                              _buildRoleFilterChip('Faculty', 'Faculty ($facultyCount)', Icons.badge_rounded),
                              const SizedBox(width: 6),
                              _buildRoleFilterChip('Department HOD', 'HODs', Icons.domain_rounded),
                              const SizedBox(width: 6),
                              _buildRoleFilterChip('Admin', 'Admins', Icons.admin_panel_settings_rounded),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      // Controls Bar (Search Input + Status Filter + View Toggle)
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 8 : 14),
                        child: LayoutBuilder(
                          builder: (context, filterConstraints) {
                            final isSmall = filterConstraints.maxWidth < 768;

                            if (isSmall) {
                              return Column(
                                children: [
                                  SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(fontSize: 12),
                                      onChanged: (val) => setState(() {
                                        _searchQuery = val;
                                        _currentPage = 1;
                                      }),
                                      decoration: InputDecoration(
                                        hintText: 'Search by name, email, ID...',
                                        hintStyle: const TextStyle(fontSize: 12),
                                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0052CC), size: 18),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 16),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = '';
                                                    _currentPage = 1;
                                                  });
                                                },
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 36,
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _selectedStatus,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            ),
                                            items: ['All', 'Active', 'Pending', 'Inactive'].map((status) => DropdownMenuItem(value: status, child: Text('Status: $status', style: const TextStyle(fontSize: 11)))).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                _selectedStatus = val;
                                                _currentPage = 1;
                                              });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Table View',
                                              icon: Icon(Icons.table_chart_rounded, color: _isTableView ? const Color(0xFF0052CC) : const Color(0xFF64748B), size: 18),
                                              onPressed: () => setState(() => _isTableView = true),
                                            ),
                                            IconButton(
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Grid Card View',
                                              icon: Icon(Icons.grid_view_rounded, color: !_isTableView ? const Color(0xFF0052CC) : const Color(0xFF64748B), size: 18),
                                              onPressed: () => setState(() => _isTableView = false),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() {
                                      _searchQuery = val;
                                      _currentPage = 1;
                                    }),
                                    decoration: InputDecoration(
                                      hintText: 'Search user by name, email, phone, or ID...',
                                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0052CC)),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                  _currentPage = 1;
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Filter Status',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    items: ['All', 'Active', 'Pending', 'Inactive'].map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                        _selectedStatus = val;
                                        _currentPage = 1;
                                      });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Table View',
                                        icon: Icon(Icons.table_chart_rounded, color: _isTableView ? const Color(0xFF0052CC) : const Color(0xFF64748B), size: 20),
                                        onPressed: () => setState(() => _isTableView = true),
                                      ),
                                      IconButton(
                                        tooltip: 'Grid Card View',
                                        icon: Icon(Icons.grid_view_rounded, color: !_isTableView ? const Color(0xFF0052CC) : const Color(0xFF64748B), size: 20),
                                        onPressed: () => setState(() => _isTableView = false),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content View (Loading / Empty State / Table View / Grid Card View)
                if (usersNotifier.isLoading && users.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0052CC)),
                        SizedBox(height: 20),
                        Text('Fetching real-time user records from master database...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        SizedBox(height: 6),
                        Text('Connecting to central admin_users directory', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                else if (filteredUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 14),
                        const Text('No User Accounts Found in Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        const Text('No database records match your active query or search parameters.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedRole = 'All';
                              _selectedStatus = 'All';
                              _currentPage = 1;
                            });
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      if (_isTableView) _buildUsersDataTable(paginatedUsers, filteredUsers.length) else _buildUsersGridCards(paginatedUsers),
                      const SizedBox(height: 16),
                      _buildPaginationBar(filteredUsers.length, totalPages, safePage),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersDataTable(List<UserModel> usersList, int totalFilteredCount) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Directory List ($totalFilteredCount Accounts)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Displaying ${usersList.length} of $totalFilteredCount entries',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    horizontalMargin: 20,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('User Profile & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('System Role', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: usersList.map((user) {
                      final initials = user.name.isNotEmpty ? user.name.substring(0, user.name.length >= 2 ? 2 : 1).toUpperCase() : 'US';

                      return DataRow(
                        cells: [
                          DataCell(
                            InkWell(
                              onTap: () => context.go('${RouteNames.users}/${user.id}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    child: Text(
                                      initials,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                      Text('ID: ${user.id}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(user.email, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(user.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            ),
                          ),
                          DataCell(Text(user.department, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                          DataCell(_buildStatusChip(user.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'View User Dossier',
                                  icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0052CC)),
                                  onPressed: () => context.go('${RouteNames.users}/${user.id}'),
                                ),
                                IconButton(
                                  tooltip: 'Quick Edit User Details',
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                  onPressed: () => _showQuickEditModal(user),
                                ),
                                IconButton(
                                  tooltip: 'Delete User Account',
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                  onPressed: () => _confirmDelete(user),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

  Widget _buildUsersGridCards(List<UserModel> usersList) => LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisExtent: isMobile ? 215 : 210,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: usersList.length,
          itemBuilder: (context, index) {
            final user = usersList[index];
            final initials = user.name.isNotEmpty ? user.name.substring(0, user.name.length >= 2 ? 2 : 1).toUpperCase() : 'US';

            return Container(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC), fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusChip(user.status),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Role', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(user.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Department', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(user.department, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('View Dossier', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          foregroundColor: const Color(0xFF0052CC),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => context.go('${RouteNames.users}/${user.id}'),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Quick Edit User Details',
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                            onPressed: () => _showQuickEditModal(user),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Delete User Account',
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            onPressed: () => _confirmDelete(user),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

  Widget _buildRoleFilterChip(String roleValue, String label, IconData icon) {
    final isSelected = _selectedRole == roleValue;
    return InkWell(
      onTap: () => setState(() => _selectedRole = roleValue),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052CC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0052CC) : const Color(0xFFCBD5E1)),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0052CC).withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isDone = status == 'Active';
    final isPending = status == 'Pending';
    final color = isDone ? const Color(0xFF16A34A) : (isPending ? const Color(0xFFD97706) : const Color(0xFF64748B));
    final bgColor = isDone ? const Color(0xFFDCFCE7) : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
