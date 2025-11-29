import 'package:flutter/material.dart';
import 'home_customer.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/menu_models.dart';

class CustomerNavigation extends StatefulWidget {
  final String establishmentId;
  final String? tableId; // Make tableId optional

  const CustomerNavigation({
    super.key,
    required this.establishmentId,
    this.tableId, // Now optional
  });

  @override
  State<CustomerNavigation> createState() => _CustomerNavigationState();
}

class _CustomerNavigationState extends State<CustomerNavigation> {
  int _currentIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  String? _resolvedTableId;

  // Cart state management - using CartItem from menu_models.dart
  final Map<String, CartItem> _cartItems = {};
  double get _cartTotal => _cartItems.values
      .fold(0, (total, item) => total + (item.menuItem.price * item.quantity));

  int get _cartItemCount => _cartItems.values
      .fold(0, (count, item) => count + item.quantity);

  @override
  void initState() {
    super.initState();
    _resolveTableId();
  }

  // Resolve table ID - use provided tableId or get a default one
  Future<void> _resolveTableId() async {
    if (widget.tableId != null) {
      setState(() {
        _resolvedTableId = widget.tableId;
      });
    } else {
      final defaultTableId = await _getDefaultTableId();
      setState(() {
        _resolvedTableId = defaultTableId;
      });
    }
  }

  // Get default table ID for the establishment
  Future<String> _getDefaultTableId() async {
    try {
      final response = await _supabaseService.client
          .from('tables')
          .select('id')
          .eq('establishment_id', widget.establishmentId)
          .eq('is_available', true)
          .limit(1);

      if (response.isNotEmpty && response[0]['id'] != null) {
        return response[0]['id'] as String;
      }
      return 'default-table-id'; // Fallback
    } catch (e) {
      debugPrint('Error getting default table ID: $e');
      return 'default-table-id'; // Fallback
    }
  }

  // Get default establishment ID (if needed for other operations)
  Future<String> _getDefaultEstablishmentId() async {
    // You might want to implement this based on your app logic
    return widget.establishmentId;
  }

  // Add to cart functionality
  void _addToCart(MenuItem menuItem, {int quantity = 1}) {
    setState(() {
      if (_cartItems.containsKey(menuItem.id)) {
        _cartItems[menuItem.id] = CartItem(
          menuItem: menuItem,
          quantity: _cartItems[menuItem.id]!.quantity + quantity,
        );
      } else {
        _cartItems[menuItem.id] = CartItem(
          menuItem: menuItem,
          quantity: quantity,
        );
      }
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem.name} added to cart'),
        backgroundColor: const Color(0xFF53B175),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Update cart item quantity
  void _updateCartQuantity(String menuItemId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.remove(menuItemId);
      } else {
        _cartItems[menuItemId] = CartItem(
          menuItem: _cartItems[menuItemId]!.menuItem,
          quantity: newQuantity,
        );
      }
    });
  }

  // Remove from cart
  void _removeFromCart(String menuItemId) {
    setState(() {
      _cartItems.remove(menuItemId);
    });
  }

  // Clear entire cart
  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  // Handle checkout process
  void _handleCheckout() async {
    // Ensure we have a table ID before proceeding
    if (_resolvedTableId == null) {
      await _resolveTableId();
    }

    // TODO: Implement checkout logic using _resolvedTableId
    debugPrint('Checkout for table: $_resolvedTableId');
    debugPrint('Total items: ${_cartItems.length}');
    debugPrint('Total amount: $_cartTotal');

    // Show placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: Text('Proceed with checkout for table $_resolvedTableId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual checkout logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: Color(0xFF53B175),
                ),
              );
              _clearCart(); // Clear cart after successful checkout
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeCustomer(
        establishmentId: widget.establishmentId,
        onAddToCart: _addToCart,
        cartItemCount: _cartItemCount,
      ),
      FavoritesScreen(
        onAddToCart: _addToCart,
      ),
      CartScreen(
        establishmentId: widget.establishmentId,
        cartItems: _cartItems,
        onUpdateQuantity: _updateCartQuantity,
        onRemoveFromCart: _removeFromCart,
        onClearCart: _clearCart,
        cartTotal: _cartTotal,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF53B175),
          unselectedItemColor: const Color(0xFF7C7C7C),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF53B175),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _cartItemCount > 9 ? '9+' : _cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF53B175),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _cartItemCount > 9 ? '9+' : _cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}