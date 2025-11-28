import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://xsflgrmqvnggtdggacrd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzZmxncm1xdm5nZ3RkZ2dhY3JkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyODQxNDMsImV4cCI6MjA3OTg2MDE0M30.Zql86YOeDJd7-chsptN3_DNNLMJLyaEY5xdGRaIQ1qs';

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Add these helpful getters for easier access
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;
  bool get isAuthenticated => client.auth.currentUser != null;

  // Auth methods for login/signup
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String userType,
    String? fullName,
    String? phone,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'user_type': userType,
        'full_name': fullName,
        'phone': phone,
      },
    );
  }
}