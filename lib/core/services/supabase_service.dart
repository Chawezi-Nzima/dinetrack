import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_models.dart';

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

  // ==================== HOME SCREEN DATA METHODS ====================

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Fetch all active categories for the current establishment
  Future<List<AppCategory>> getCategories({String? establishmentId}) async {
    try {
      final response = await client
          .from('menu_categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List).map((json) => AppCategory.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Fetch bestseller items
  Future<List<MenuItem>> getBestsellers() async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('is_bestseller', true)
          .eq('is_available', true)
          .order('name');

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching bestsellers: $e');
      return [];
    }
  }

  // Fetch recommended items
  Future<List<MenuItem>> getRecommended() async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('is_recommended', true)
          .eq('is_available', true)
          .order('name');

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching recommended items: $e');
      return [];
    }
  }

  // Search menu items - UPDATED to use ilike and include categories
  Future<List<MenuItem>> searchMenuItems(String query) async {
    try {
      final response = await client
          .from('menu_items')
          .select('''
            *,
            menu_categories!inner(
              name,
              establishment_id
            )
          ''')
          .ilike('name', '%$query%')
          .eq('is_available', true);

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error searching menu items: $e');
      return [];
    }
  }

  // Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(String categoryId) async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('name');

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching menu items by category: $e');
      return [];
    }
  }

  // Get all available menu items
  Future<List<MenuItem>> getAllMenuItems() async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('is_available', true)
          .order('name');

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all menu items: $e');
      return [];
    }
  }

  // Get user favorites
  Future<List<MenuItem>> getUserFavorites() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      final response = await client
          .from('user_favorites')
          .select('''
            menu_items(*)
          ''')
          .eq('user_id', user.id);

      return (response as List)
          .map((json) => MenuItem.fromJson(json['menu_items']))
          .toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  // Add item to favorites
  Future<void> addToFavorites(String menuItemId) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await client.from('user_favorites').insert({
        'user_id': user.id,
        'menu_item_id': menuItemId,
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String menuItemId) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await client
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('menu_item_id', menuItemId);
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Add item to cart (creates or updates an order)
  Future<void> addToCart(String menuItemId, int quantity) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, check if user has an active order
      final activeOrders = await client
          .from('orders')
          .select()
          .eq('customer_id', user.id)
          .inFilter('status', ['pending', 'confirmed'])
          .limit(1);

      String orderId;

      if (activeOrders.isEmpty) {
        // Create a new order
        final newOrder = await client
            .from('orders')
            .insert({
          'customer_id': user.id,
          'establishment_id': await _getDefaultEstablishmentId(),
          'table_id': await _getDefaultTableId(),
          'status': 'pending',
          'total_amount': 0,
        })
            .select()
            .single();

        orderId = newOrder['id'] as String;
      } else {
        orderId = activeOrders.first['id'] as String;
      }

      // Get menu item price
      final menuItem = await client
          .from('menu_items')
          .select('price')
          .eq('id', menuItemId)
          .single();

      final price = (menuItem['price'] as num).toDouble();
      final lineTotal = price * quantity;

      // Add item to order
      await client.from('order_items').insert({
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'unit_price': price,
        'line_total': lineTotal,
      });

      // Update order total
      await _updateOrderTotal(orderId);

    } catch (e) {
      print('Error adding item to cart: $e');
      rethrow;
    }
  }

  // Get cart items for current user
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      final activeOrders = await client
          .from('orders')
          .select()
          .eq('customer_id', user.id)
          .inFilter('status', ['pending', 'confirmed'])
          .limit(1);

      if (activeOrders.isEmpty) return [];

      final orderId = activeOrders.first['id'] as String;

      final response = await client
          .from('order_items')
          .select('''
            *,
            menu_items (
              name,
              description,
              image_url
            )
          ''')
          .eq('order_id', orderId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  Future<void> _updateOrderTotal(String orderId) async {
    try {
      // Calculate total from order items
      final orderItems = await client
          .from('order_items')
          .select('line_total')
          .eq('order_id', orderId);

      double total = 0;
      for (final item in orderItems) {
        total += (item['line_total'] as num).toDouble();
      }

      // Update order total
      await client
          .from('orders')
          .update({'total_amount': total})
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order total: $e');
    }
  }

  Future<String> _getDefaultEstablishmentId() async {
    // In a real app, you might want to get this from user preferences or context
    // For now, return the first active establishment
    try {
      final response = await client
          .from('establishments')
          .select('id')
          .eq('is_active', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      }

      // Fallback - you might want to handle this differently
      return 'default-establishment-id';
    } catch (e) {
      print('Error getting default establishment: $e');
      return 'default-establishment-id';
    }
  }

  Future<String> _getDefaultTableId() async {
    // In a real app, this would come from QR code scan or user selection
    try {
      final establishmentId = await _getDefaultEstablishmentId();
      final response = await client
          .from('tables')
          .select('id')
          .eq('establishment_id', establishmentId)
          .eq('is_available', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      }

      return 'default-table-id';
    } catch (e) {
      print('Error getting default table: $e');
      return 'default-table-id';
    }
  }

  // ==================== ORDER MANAGEMENT ====================

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await client
          .from('orders')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String orderItemId) async {
    try {
      await client
          .from('order_items')
          .delete()
          .eq('id', orderItemId);
    } catch (e) {
      print('Error removing item from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String orderId) async {
    try {
      await client
          .from('order_items')
          .delete()
          .eq('order_id', orderId);

      await _updateOrderTotal(orderId);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  Stream<List<MenuItem>> getMenuItemsStream() {
    return client
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .map((event) => event.map((json) => MenuItem.fromJson(json)).toList());
  }

  Stream<List<Map<String, dynamic>>> getOrderStream(String orderId) {
    return client
        .from('order_items')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map((event) => event.cast<Map<String, dynamic>>());
  }

  // Storage URL helper method
  String storagePublicUrl(String bucketName, String filePath) {
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$filePath';
  }

  // Add to SupabaseService class
  Future<List<MenuItem>> getMenuItemsByEstablishment(String establishmentId) async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('establishment_id', establishmentId)
          .eq('is_available', true)
          .order('name');

      return (response as List).map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }
}