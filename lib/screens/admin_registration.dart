import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_verification_screen.dart';
import '../../../restaurantRegistrationPage.dart';

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({super.key});

  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerAdmin() async {
    if (!_formKey.currentState!.validate()) return;


    setState(() => _isLoading = true);

    try {
      print('DEBUG: Starting admin registration with email: ${_emailCtrl.text.trim()}');

      // 1. Create admin user account
      final authResponse = await _supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        data: {
          'full_name': _nameCtrl.text.trim(),
          'user_type': 'operator',
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create admin account');
      }

      final userId = authResponse.user!.id;
      print('DEBUG: Admin auth user created with ID: $userId');

      // 2. Create user record in public.users table
      try {
        await _supabase.from('users').insert({
          'id': userId,
          'email': _emailCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
          'user_type': 'operator',
          'dine_coins_balance': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('DEBUG: Admin user record created successfully');
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // User already exists, update instead
          await _supabase.from('users').update({
            'full_name': _nameCtrl.text.trim(),
            'user_type': 'operator',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
          print('DEBUG: Admin user record updated successfully');
        } else {
          rethrow;
        }
      }

      // 3. Create profile record
      try {
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': _nameCtrl.text.trim(),
          'role': 'restaurant_admin',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('DEBUG: Admin profile created successfully');
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await _supabase.from('profiles').update({
            'full_name': _nameCtrl.text.trim(),
            'role': 'restaurant_admin',
          }).eq('id', userId);
          print('DEBUG: Admin profile updated successfully');
        } else {
          rethrow;
        }
      }

      // Success - Show email verification message
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
                        'Admin Account Created Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Please check your email (${_emailCtrl.text.trim()}) for verification link.',
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
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to success screen with instructions
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: _emailCtrl.text.trim(),
                userId: userId,
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      _showErrorSnackBar('Authentication Error: ${e.message}');
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

  void _handleDatabaseError(PostgrestException e) {
    String errorMessage;

    if (e.code == '23505' || e.message?.contains('duplicate') == true) {
      errorMessage = 'This email is already registered. Please login instead.';
    } else if (e.code == '409') {
      errorMessage = 'Account already exists. Please login instead.';
    } else if (e.message?.contains('violates row-level security policy') == true) {
      errorMessage = 'Permission denied. Please contact support.';
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

  @override
  Widget build(BuildContext context) {
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
          "Admin Registration",
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
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
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
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create Admin Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'First, create your admin account. Then register your restaurant.',
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
                  padding: const EdgeInsets.all(24),
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
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: "Full Name",
                          hint: "John Doe",
                          icon: Icons.person,
                          validatorMsg: "Enter your full name",
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailCtrl,
                          label: "Email Address",
                          hint: "admin@example.com",
                          icon: Icons.email,
                          validatorMsg: "Enter your email",
                          keyboard: TextInputType.emailAddress,
                          extraValidator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(value)) {
                                return "Enter a valid email address";
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordCtrl,
                          label: "Password",
                          hint: "At least 8 characters",
                          icon: Icons.lock,
                          isPassword: true,
                          showPassword: _showPassword,
                          onTogglePassword: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          validatorMsg: "Enter password",
                          extraValidator: (value) {
                            if (value != null) {
                              if (value.length < 8) {
                                return "Password must be at least 8 characters";
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return "Include at least one uppercase letter";
                              }
                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return "Include at least one lowercase letter";
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return "Include at least one number";
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _confirmPasswordCtrl,
                          label: "Confirm Password",
                          hint: "Re-enter your password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          showPassword: _showConfirmPassword,
                          onTogglePassword: () {
                            setState(() => _showConfirmPassword = !_showConfirmPassword);
                          },
                          validatorMsg: "Confirm password",
                          extraValidator: (value) {
                            if (value != _passwordCtrl.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Terms and Conditions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              child: const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You will receive an email verification link. Click it to verify your account, then you can register your restaurant.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280).withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerAdmin,
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
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  "Create Admin Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Already have account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an admin account?',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to admin login
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? extraValidator,
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
          obscureText: isPassword && !showPassword,
          keyboardType: keyboard,
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
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
                size: 22,
              ),
              onPressed: onTogglePassword,
            )
                : null,
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
            if (extraValidator != null) return extraValidator(value);
            return null;
          },
        ),
      ],
    );
  }
}