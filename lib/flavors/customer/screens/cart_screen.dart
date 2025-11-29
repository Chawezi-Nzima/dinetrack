import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/menu_models.dart';

class CartScreen extends StatelessWidget {
  final String establishmentId;
  final Map<String, CartItem> cartItems;
  final Function(String, int) onUpdateQuantity;
  final Function(String) onRemoveFromCart;
  final Function() onClearCart;
  final double cartTotal;
  final Color _primaryGreen = const Color(0xFF53B175);

  const CartScreen({
    super.key,
    required this.establishmentId,
    required this.cartItems,
    required this.onUpdateQuantity,
    required this.onRemoveFromCart,
    required this.onClearCart,
    required this.cartTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.grey),
              onPressed: () => _showClearCartDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const Divider(height: 30),
              itemBuilder: (context, index) {
                final cartItem = cartItems.values.elementAt(index);
                final menuItem = cartItem.menuItem;
                final quantity = cartItem.quantity;
                final price = menuItem.price;
                final imageUrl = menuItem.imageUrl;

                return _buildCartItem(
                  context,
                  cartItem,
                  menuItem,
                  quantity,
                  price,
                  imageUrl,
                );
              },
            ),
          ),

          // Checkout Section
          if (cartItems.isNotEmpty) _buildCheckoutSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      CartItem cartItem,
      MenuItem menuItem,
      int quantity,
      double price,
      String? imageUrl,
      ) {
    return Row(
      children: [
        // Image
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.fastfood, color: Colors.grey);
              },
            ),
          )
              : const Icon(Icons.fastfood, color: Colors.grey),
        ),
        const SizedBox(width: 15),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menuItem.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                menuItem.description ?? "Fresh and delicious",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Quantity Controls
              Row(
                children: [
                  _buildQuantityButton(
                    Icons.remove,
                        () => onUpdateQuantity(menuItem.id, quantity - 1),
                    enabled: quantity > 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildQuantityButton(
                    Icons.add,
                        () => onUpdateQuantity(menuItem.id, quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Price & Remove
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => onRemoveFromCart(menuItem.id),
            ),
            Text(
              '${(price * quantity).toStringAsFixed(0)} MWK',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton(
      IconData icon,
      VoidCallback onTap, {
        bool enabled = true,
      }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? (icon == Icons.add ? _primaryGreen : Colors.grey.shade300)
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? (icon == Icons.add ? _primaryGreen : Colors.grey)
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '${cartTotal.toStringAsFixed(0)} MWK',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Call Place Order Logic
                  _showCheckoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Go to Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onClearCart();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${cartTotal.toStringAsFixed(0)} MWK'),
            const SizedBox(height: 10),
            Text('Items: ${cartItems.length}'),
            const SizedBox(height: 20),
            const Text(
              'Checkout functionality will be implemented soon!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}