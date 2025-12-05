import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantRegistrationPage extends StatefulWidget {
  final String userId; // Admin user ID passed from previous screen

  const RestaurantRegistrationPage({
    super.key,
    required this.userId,
  });

  @override
  State<RestaurantRegistrationPage> createState() =>
      _RestaurantRegistrationPageState();
}

class _RestaurantRegistrationPageState
    extends State<RestaurantRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Restaurant fields only (no admin fields)
  final TextEditingController restaurantNameCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController typeCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    restaurantNameCtrl.dispose();
    locationCtrl.dispose();
    phoneCtrl.dispose();
    typeCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || currentUser.id != widget.userId) {
      // User is not logged in or wrong user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login with your verified admin account'),
          backgroundColor: Colors.orange,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _registerRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('DEBUG: Starting restaurant registration for user: ${widget.userId}');

      // 1. Create restaurant (establishment) entry
      final restaurantType = typeCtrl.text.trim().toLowerCase();
      final validType = restaurantType == 'pub' ? 'pub' : 'restaurant';

      print('DEBUG: Creating restaurant establishment');
      final restaurantResponse = await _supabase
          .from('establishments')
          .insert({
        'owner_id': widget.userId,
        'name': restaurantNameCtrl.text.trim(),
        'address': locationCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'type': validType,
        'description': descriptionCtrl.text.trim(),
        'dine_coins_balance': 0,
        'is_active': true,
        'supervisor_approved': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      final establishmentId = restaurantResponse['id'] as String;
      print('DEBUG: Establishment created with ID: $establishmentId');

      // 2. Create staff assignment for admin
      print('DEBUG: Creating staff assignment');
      await _supabase.from('staff_assignments').insert({
        'user_id': widget.userId,
        'establishment_id': establishmentId,
        'role': 'manager',
        'name': await _getAdminName(),
        'email': await _getAdminEmail(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('DEBUG: Staff assignment created');

      // 3. Create default tables for the restaurant
      await _createDefaultTables(establishmentId);

      // 4. Create default menu categories
      await _createDefaultMenuCategories(establishmentId);

      // Success!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restaurant Registered Successfully!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Awaiting supervisor approval before activation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to admin dashboard
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          // TODO: Navigate to admin dashboard
          Navigator.pushReplacementNamed(context, '/operator-home');

        }
      }
    } on PostgrestException catch (e) {
      _handleDatabaseError(e);
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _getAdminName() async {
    final user = await _supabase
        .from('users')
        .select('full_name')
        .eq('id', widget.userId)
        .single();
    return user['full_name'] as String;
  }

  Future<String> _getAdminEmail() async {
    final user = await _supabase
        .from('users')
        .select('email')
        .eq('id', widget.userId)
        .single();
    return user['email'] as String;
  }

  void _handleDatabaseError(PostgrestException e) {
    String errorMessage;

    if (e.message?.contains('violates row-level security policy') == true) {
      errorMessage = 'Permission denied. Please ensure RLS policies allow restaurant creation.';
    } else if (e.message?.contains('check constraint') == true) {
      errorMessage = 'Data validation failed. Please check all fields.';
    } else {
      errorMessage = 'Database Error: ${e.message}';
    }

    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    print('ERROR: $message');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createDefaultTables(String establishmentId) async {
    try {
      print('DEBUG: Creating default tables');
      for (int i = 1; i <= 10; i++) {
        await _supabase.from('tables').insert({
          'establishment_id': establishmentId,
          'label': 'Table $i',
          'table_number': i,
          'capacity': i <= 4 ? 4 : 6,
          'is_available': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      print('DEBUG: Default tables created successfully');
    } catch (e) {
      print('WARNING: Default tables not created - $e');
    }
  }

  Future<void> _createDefaultMenuCategories(String establishmentId) async {
    try {
      print('DEBUG: Creating default menu categories');
      final defaultCategories = [
        {'name': 'Appetizers', 'description': 'Start your meal right', 'display_order': 1},
        {'name': 'Main Course', 'description': 'Hearty main dishes', 'display_order': 2},
        {'name': 'Desserts', 'description': 'Sweet endings', 'display_order': 3},
        {'name': 'Beverages', 'description': 'Drinks and refreshments', 'display_order': 4},
      ];

      for (final category in defaultCategories) {
        await _supabase.from('menu_categories').insert({
          'establishment_id': establishmentId,
          'name': category['name'],
          'description': category['description'],
          'display_order': category['display_order'],
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      print('DEBUG: Default menu categories created successfully');
    } catch (e) {
      print('WARNING: Default categories not created - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register Your Restaurant",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 800,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            child: Column(
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Register Your Restaurant',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete your restaurant details to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: restaurantNameCtrl,
                          label: "Restaurant Name",
                          hint: "e.g., The Golden Fork",
                          icon: Icons.restaurant_menu,
                          validatorMsg: "Enter restaurant name",
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: locationCtrl,
                          label: "Location Address",
                          hint: "Full address",
                          icon: Icons.location_on,
                          validatorMsg: "Enter location address",
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: phoneCtrl,
                          label: "Phone Number",
                          hint: "+265 123 456 789",
                          icon: Icons.phone,
                          keyboard: TextInputType.phone,
                          validatorMsg: "Enter phone number",
                        ),
                        const SizedBox(height: 16),

                        // Restaurant Type Dropdown
                        _buildTypeDropdown(),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: descriptionCtrl,
                          label: "Description",
                          hint: "Tell us about your restaurant...",
                          icon: Icons.description,
                          maxLines: 4,
                          validatorMsg: "Enter description",
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerRestaurant,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              disabledBackgroundColor:
                              const Color(0xFF4F46E5).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  "Complete Restaurant Registration",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? validatorMsg,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF).withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 22),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (validatorMsg != null && (value == null || value.isEmpty)) {
              return validatorMsg;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Restaurant Type",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: typeCtrl.text.isNotEmpty ? typeCtrl.text : null,
          onChanged: (value) {
            setState(() {
              typeCtrl.text = value ?? '';
            });
          },
          decoration: InputDecoration(
            hintText: "Select restaurant type",
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF).withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.category, color: Color(0xFF6B7280), size: 22),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: const [
            DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
            DropdownMenuItem(value: 'pub', child: Text('Pub')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Select restaurant type";
            }
            return null;
          },
        ),
      ],
    );
  }
}