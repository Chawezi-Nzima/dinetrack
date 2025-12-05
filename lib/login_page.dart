// login_page.dart - Update the login function
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dinetrack/flavors/customer/screens/registration.dart';
import 'core/utils/platform_detector.dart';
import 'core/services/supabase_service.dart';
import 'landingPage.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfShouldRedirect();
  }

  void _checkIfShouldRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If user is on desktop web, suggest using web interface
      if (PlatformDetector.isDesktopWeb) {
        _showDesktopRedirectDialog();
      }
    });
  }

  void _showDesktopRedirectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.desktop_windows, color: Colors.blue),
            SizedBox(width: 12),
            Text('Desktop Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'re accessing DineTrack from a desktop browser.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'For the best experience, we recommend using:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.web, color: Colors.green),
              title: const Text('Desktop Web Interface'),
              subtitle: const Text('Full features, better layout'),
              onTap: () {
                Navigator.pop(context);
                _redirectToWebInterface();
              },
            ),
            const Divider(),
            const Text(
              'Continue with mobile interface for:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip(Icons.phone_android, 'Phone Testing'),
                _buildChip(Icons.tablet, 'Tablet View'),
                _buildChip(Icons.developer_mode, 'Developer Mode'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Use Mobile Interface'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _redirectToWebInterface();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Web Interface'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }

  void _redirectToWebInterface() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LandingPage()),
    );
  }

  Future<void> _loginWithEmailPassword() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      // 1. Login user
      final response = await SupabaseService().client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;

      if (user == null) {
        setState(() => _errorMessage = "Login failed: no user returned.");
        return;
      }

      print("LOGGED IN USER: ${user.id}");

      // 2. Check if user metadata already exists
      final existing = await SupabaseService()
          .client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        print("User metadata does NOT exist — inserting new row...");

        // 3. Insert metadata on first login after email verification
        final insertResponse = await SupabaseService()
            .client
            .from('users')
            .insert({
          'id': user.id,
          'email': user.email,
          'full_name': '', // optional: fill using saved controllers
          'phone': '',
          'user_type': 'customer',
          'dine_coins_balance': 0,
        })
            .select()
            .single();

        print("USER METADATA INSERTED: $insertResponse");
      } else {
        print("User metadata already exists — skipping insert.");
      }

      // 🔴 FIXED: Trigger navigation by updating auth state
      // The AuthGate will detect the session change and navigate

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // The navigation will be handled by AuthGate stream
      // Don't call Navigator here

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
      // 1. Login using the guest account
      final response = await SupabaseService().client.auth.signInWithPassword(
        email: 'guest@dinetrack.com',
        password: 'guest123456',
      );

      final user = response.user;

      if (user == null) {
        throw Exception("Guest login succeeded but user is null");
      }

      // 2. Insert customer row if not exists
      final insertPayload = {
        "id": user.id,
        "email": "guest@dinetrack.com",
        "full_name": "Guest User",
        "phone": "",
        "user_type": "customer",
        "dine_coins_balance": "0.00",
      };

      // Uses UPSERT so duplicates don't throw errors
      await SupabaseService()
          .client
          .from("users")
          .upsert(insertPayload);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigation will be handled by AuthGate

    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Failed to login as guest: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to login as guest: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        title: const Text('DineTrack Mobile'),
        actions: [
          if (PlatformDetector.isWeb)
            IconButton(
              icon: const Icon(Icons.desktop_windows),
              onPressed: _showDesktopRedirectDialog,
              tooltip: 'Switch to desktop interface',
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
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
                              onPressed: _busy
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                                );
                              },
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

          // Platform indicator
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                PlatformDetector.isWeb ? 'Mobile Web' : 'Mobile App',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
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