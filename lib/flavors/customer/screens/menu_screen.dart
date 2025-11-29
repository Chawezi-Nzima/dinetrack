import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/menu_models.dart';
import 'item_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final String establishmentId;
  final Function(MenuItem, int) onAddToCart;
  final int cartItemCount;

  const MenuScreen({
    super.key,
    required this.establishmentId,
    required this.onAddToCart,
    this.cartItemCount = 0,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final SupabaseService _svc = SupabaseService();
  List<MenuItem> _items = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> _filteredItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      // Use getCategories and get menu items from categories, or use getAllMenuItems if available
      final categories = await _svc.getCategories();
      // For now, let's use a method that exists - you'll need to implement proper menu item fetching
      final items = await _getAllMenuItems();
      setState(() {
        _items = items;
        _filteredItems = items;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading items: $e");
      setState(() => _loading = false);
    }
  }

  // Temporary method - you'll need to implement proper menu item fetching in SupabaseService
  Future<List<MenuItem>> _getAllMenuItems() async {
    // This is a placeholder - implement proper menu item fetching in your SupabaseService
    try {
      // Try using existing methods or implement a new one
      final bestsellers = await _svc.getBestsellers();
      final recommended = await _svc.getRecommended();

      // Combine and remove duplicates
      final allItems = <MenuItem>[];
      final seenIds = <String>{};

      for (final item in bestsellers) {
        if (!seenIds.contains(item.id)) {
          allItems.add(item);
          seenIds.add(item.id);
        }
      }

      for (final item in recommended) {
        if (!seenIds.contains(item.id)) {
          allItems.add(item);
          seenIds.add(item.id);
        }
      }

      return allItems;
    } catch (e) {
      debugPrint("Error getting menu items: $e");
      return [];
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) =>
        item.name.toLowerCase().contains(query) ||
            (item.description?.toLowerCase().contains(query) ?? false)).toList();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filteredItems = _items;
    });
  }

  void _refreshItems() {
    setState(() {
      _loading = true;
    });
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
            'Find Products',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.black),
                onPressed: () {
                  // TODO: Navigate to cart screen or show cart dialog
                },
              ),
              if (widget.cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      widget.cartItemCount > 9 ? '9+' : widget.cartItemCount.toString(),
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
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Store',
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ),

          // Grid Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF53B175)))
                : _filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () async {
                _refreshItems();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildProductCard(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.fastfood_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No items found' : 'No menu items available',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Check back later for new items',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53B175),
              ),
              child: const Text(
                'Clear Search',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(MenuItem item) {
    final imageUrl = item.imageUrl ?? 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () => _navigateToItemDetail(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description ?? "Fresh and delicious",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onAddToCart(item, 1),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF53B175),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToItemDetail(BuildContext context, MenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(
        item: item, // Pass MenuItem directly
        onAddToCart: widget.onAddToCart, // Pass the onAddToCart function
      )),
    );
  }
}