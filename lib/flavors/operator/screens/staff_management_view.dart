// lib/flavors/operator/screens/staff_management_view.dart
import 'package:flutter/material.dart';
import 'package:dinetrack/core/services/supabase_service.dart';

class StaffManagementView extends StatefulWidget {
  final String establishmentId;
  final bool isDarkMode;
  final VoidCallback onStaffAdded;

  const StaffManagementView({
    super.key,
    required this.establishmentId,
    required this.isDarkMode,
    required this.onStaffAdded,
  });

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  final supabase = SupabaseService().client;
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> kitchenStaffList = [];
  bool isLoading = true;
  bool isAddingStaff = false;
  int _selectedTabIndex = 0; // 0 = Regular Staff, 1 = Kitchen Staff

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Staff type
  String _selectedUserType = 'staff'; // staff, kitchen, operator, supervisor
  String _selectedStaffRole = 'waiter'; // waiter, cashier, manager
  final _assignedStationController = TextEditingController(); // for kitchen staff
  final _assignedTablesController = TextEditingController(); // for waiters (comma separated)

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => isLoading = true);

    try {
      // Load regular staff (staff_assignments)
      final staffResponse = await supabase
          .from('staff_assignments')
          .select('*, users(full_name, email, phone, user_type)')
          .eq('establishment_id', widget.establishmentId)
          .eq('is_active', true)
          .order('role')
          .order('name');

      staffList = List<Map<String, dynamic>>.from(staffResponse as List);

      // Load kitchen staff (kitchen_assignments)
      final kitchenResponse = await supabase
          .from('kitchen_assignments')
          .select('*, users(full_name, email, phone, user_type)')
          .eq('establishment_id', widget.establishmentId)
          .eq('is_active', true)
          .order('assigned_station');

      kitchenStaffList = List<Map<String, dynamic>>.from(kitchenResponse as List);

    } catch (e) {
      print('Error loading staff data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addStaffMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isAddingStaff = true);

    try {
      // 1. First check if user exists with this email
      final existingUsers = await supabase
          .from('users')
          .select('id, email')
          .eq('email', _emailController.text.trim());

      String userId;

      if (existingUsers != null && existingUsers.isNotEmpty) {
        // User already exists - use existing ID
        userId = existingUsers[0]['id'].toString();
        print('Using existing user ID: $userId');
      } else {
        // Create new auth user
        final authResponse = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (authResponse.user == null) {
          throw Exception('Failed to create auth user');
        }

        userId = authResponse.user!.id;
        print('Created new auth user ID: $userId');

        // Create user in public.users table
        await supabase.from('users').insert({
          'id': userId,
          'email': _emailController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          'user_type': _selectedUserType,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Create appropriate assignment based on user type
      if (_selectedUserType == 'kitchen') {
        // Create kitchen assignment
        await supabase.from('kitchen_assignments').insert({
          'user_id': userId,
          'establishment_id': widget.establishmentId,
          'assigned_station': _assignedStationController.text.trim(),
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Create staff assignment
        List<String> tables = [];
        if (_assignedTablesController.text.trim().isNotEmpty) {
          tables = _assignedTablesController.text
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
        }

        await supabase.from('staff_assignments').insert({
          'user_id': userId,
          'establishment_id': widget.establishmentId,
          'role': _selectedStaffRole,
          'name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'assigned_tables': tables.isNotEmpty ? tables : null,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_fullNameController.text} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 4. Reset form and reload data
      _resetForm();
      _loadStaffData();
      widget.onStaffAdded();

    } catch (e) {
      print('Error adding staff: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isAddingStaff = false);
    }
  }

  Future<void> _toggleStaffStatus(Map<String, dynamic> staff, bool isKitchen) async {
    try {
      if (isKitchen) {
        await supabase
            .from('kitchen_assignments')
            .update({'is_active': !(staff['is_active'] ?? true)})
            .eq('id', staff['id']);
      } else {
        await supabase
            .from('staff_assignments')
            .update({'is_active': !(staff['is_active'] ?? true)})
            .eq('id', staff['id']);
      }

      _loadStaffData();
    } catch (e) {
      print('Error toggling staff status: $e');
    }
  }

  void _resetForm() {
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _assignedStationController.clear();
    _assignedTablesController.clear();
    _selectedUserType = 'staff';
    _selectedStaffRole = 'waiter';
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff Member'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Phone (Optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),

                // User Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    labelText: 'Staff Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'staff',
                      child: Text('Front Staff (Waiter/Cashier/Manager)'),
                    ),
                    DropdownMenuItem(
                      value: 'kitchen',
                      child: Text('Kitchen Staff'),
                    ),
                    DropdownMenuItem(
                      value: 'operator',
                      child: Text('Operator'),
                    ),
                    DropdownMenuItem(
                      value: 'supervisor',
                      child: Text('Supervisor'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select staff type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Conditional Fields based on User Type
                if (_selectedUserType == 'staff') ...[
                  // Staff Role Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStaffRole,
                    decoration: const InputDecoration(
                      labelText: 'Staff Role *',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'waiter',
                        child: Text('Waiter'),
                      ),
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Text('Cashier'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Manager'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStaffRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Assigned Tables (for waiters)
                  if (_selectedStaffRole == 'waiter')
                    TextFormField(
                      controller: _assignedTablesController,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Tables (Optional, comma separated)',
                        prefixIcon: Icon(Icons.table_chart),
                        hintText: 'e.g., 1, 2, 5, 7',
                      ),
                    ),
                ],

                if (_selectedUserType == 'kitchen') ...[
                  // Assigned Station for Kitchen Staff
                  TextFormField(
                    controller: _assignedStationController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Station *',
                      prefixIcon: Icon(Icons.kitchen),
                      hintText: 'e.g., Grill, Fryer, Salad Station',
                    ),
                    validator: (value) {
                      if (_selectedUserType == 'kitchen' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Station is required for kitchen staff';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Password (only for new users)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isAddingStaff ? null : _addStaffMember,
            child: isAddingStaff
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff, bool isKitchen) {
    final user = staff['users'] ?? {};
    final isActive = staff['is_active'] ?? true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade300,
          child: Icon(
            isKitchen ? Icons.kitchen : Icons.person,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          user['full_name']?.toString() ?? staff['name']?.toString() ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']?.toString() ?? staff['email']?.toString() ?? 'No email'),
            const SizedBox(height: 4),
            Text(
              isKitchen
                  ? 'Station: ${staff['assigned_station'] ?? 'Not assigned'}'
                  : 'Role: ${staff['role'] ?? 'Staff'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (!isActive)
              Text(
                'INACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isActive ? Icons.person_off : Icons.person_add,
                color: isActive ? Colors.orange : Colors.green,
              ),
              onPressed: () => _toggleStaffStatus(staff, isKitchen),
              tooltip: isActive ? 'Deactivate' : 'Activate',
            ),
            if (user['phone']?.toString() != null)
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  // Implement call functionality
                },
                tooltip: 'Call ${user['phone']}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(List<Map<String, dynamic>> staff, bool isKitchen) {
    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isKitchen ? Icons.kitchen_outlined : Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isKitchen
                  ? 'No Kitchen Staff Found'
                  : 'No Staff Members Found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isKitchen
                  ? 'Add kitchen staff to manage your kitchen operations'
                  : 'Add staff members to manage your restaurant',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStaffData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: staff.length,
        itemBuilder: (context, index) {
          return _buildStaffCard(staff[index], isKitchen);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all staff members for your establishment',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddStaffDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Staff'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            child: Row(
              children: [
                _buildTabButton(
                  0,
                  'Front Staff (${staffList.length})',
                  Icons.people,
                ),
                _buildTabButton(
                  1,
                  'Kitchen Staff (${kitchenStaffList.length})',
                  Icons.kitchen,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildStaffList(staffList, false)
                : _buildStaffList(kitchenStaffList, true),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _assignedStationController.dispose();
    _assignedTablesController.dispose();
    super.dispose();
  }
}