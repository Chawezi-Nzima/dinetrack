import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  Future<void> _loginWithEmailPassword() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService().client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Login successful - AuthGate in main.dart will handle routing
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      // Use predefined guest account
      await SupabaseService().client.auth.signInWithPassword(
        email: 'guest@dinetrack.com',
        password: 'guest123456',
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Failed to login as guest: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to login as guest: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Optional sign up method
  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService().client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'user_type': 'customer', // Default role for new signups
          'full_name': '', // Can be updated later
        },
      );

      if (response.user != null) {
        setState(() => _errorMessage = 'Account created successfully! You can now login.');
      } else {
        setState(() => _errorMessage = 'Check your email to verify your account.');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// LOGO
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 160,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "DINETRACK",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              /// LOGIN CARD
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      const Text(
                        "Welcome",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 25),

                      /// EMAIL FIELD
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      /// PASSWORD FIELD
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 15),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _loginWithEmailPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _busy
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// SIGN UP BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _busy ? null : _signUp,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Create Account"),
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// LOGIN AS GUEST
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _busy ? null : _signInAsGuest,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Login as Guest"),
                        ),
                      ),

                      /// ERROR MESSAGE
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              /// ADDITIONAL INFO
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Contact administrator for operator/supervisor accounts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}