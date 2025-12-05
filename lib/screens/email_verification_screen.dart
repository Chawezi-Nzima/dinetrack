import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../restaurantRegistrationPage.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _supabase = Supabase.instance.client;
  bool _isVerified = false;
  bool _checking = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null && user.id == widget.userId && user.emailConfirmedAt != null) {
        setState(() {
          _isVerified = true;
        });
        _proceedToRestaurantRegistration();
      }
    });
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _checking = true);
    try {
      final session = _supabase.auth.currentSession;
      if (session != null && session.user.emailConfirmedAt != null) {
        setState(() => _isVerified = true);
        _proceedToRestaurantRegistration();
      }
    } catch (e) {
      print('Error checking verification: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _resending = true);
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _proceedToRestaurantRegistration() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantRegistrationPage(userId: widget.userId),
          ),
        );
      }
    });
  }

  void _logoutAndRestart() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Email Verification",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isVerified ? Colors.green.shade100 : Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVerified ? Icons.verified : Icons.email,
                  size: 50,
                  color: _isVerified ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                _isVerified
                    ? 'Your email has been verified successfully!'
                    : 'We sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF6B7280).withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),

              // Email
              if (!_isVerified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Instructions
              if (!_isVerified)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Instructions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('1. Check your email inbox'),
                      _buildInstruction('2. Click the verification link'),
                      _buildInstruction('3. Return to this app'),
                      _buildInstruction('4. Your account will be verified automatically'),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Actions
              if (_isVerified)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Proceeding to restaurant registration...',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checking ? null : _checkVerificationStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _checking
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 10),
                            Text(
                              'Check Verification Status',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resending ? null : _resendVerificationEmail,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: _resending
                            ? const CircularProgressIndicator()
                            : const Text('Resend Verification Email'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _logoutAndRestart,
                      child: const Text(
                        'Use different email',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF6B7280).withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}