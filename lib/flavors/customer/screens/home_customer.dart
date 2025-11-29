import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/menu_models.dart';

class HomeCustomer extends StatefulWidget {
  final String establishmentId;
  final Function(MenuItem, {int quantity}) onAddToCart;
  final int cartItemCount;

  const HomeCustomer({
    super.key,
    required this.establishmentId,
    required this.onAddToCart,
    required this.cartItemCount,
  });

  @override
  State<HomeCustomer> createState() => _HomeCustomerState();
}

class _HomeCustomerState extends State<HomeCustomer> {
  final SupabaseService _supabaseService = SupabaseService();
  final Color _primaryGreen = const Color(0xFF53B175);
  final Color _lightGrey = const Color(0xFFF2F3F2);
  final Color _darkGrey = const Color(0xFF7C7C7C);

  Future<List<AppCategory>> _categoriesFuture = Future.value([]);
  Future<List<MenuItem>> _bestsellersFuture = Future.value([]);
  Future<List<MenuItem>> _recommendedFuture = Future.value([]);
  Future<UserProfile?> _userProfileFuture = Future.value(null);

  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add search listener
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _categoriesFuture = _supabaseService.getCategories();
      _bestsellersFuture = _supabaseService.getBestsellers();
      _recommendedFuture = _supabaseService.getRecommended();
      _userProfileFuture = _supabaseService.getCurrentUserProfile();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _isSearching = query.isNotEmpty;
      });

      if (query.isNotEmpty) {
        _performSearch(query);
      }
    }
  }

  void _performSearch(String query) async {
    try {
      final results = await _supabaseService.searchMenuItems(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Search error: $e');
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _refreshData() {
    _loadData();
    if (_isSearching && _searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'DineTrack',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryGreen,
        actions: [
          // Cart badge in app bar
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  // TODO: Navigate to cart screen
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
      body: SafeArea(
        child: Column(
          children: [
            // 👤 USER HEADER
            _buildUserHeader(),

            // 📱 MAIN CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: CustomScrollView(
                  slivers: [
                    // 🔍 SEARCH BAR
                    SliverToBoxAdapter(
                      child: _buildSearchBar(),
                    ),

                    // 🎯 HERO BANNER
                    SliverToBoxAdapter(
                      child: _buildHeroBanner(),
                    ),

                    // CONTENT BASED ON SEARCH STATE
                    if (_isSearching) ..._buildSearchContent(),
                    if (!_isSearching) ..._buildMainContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchContent() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_searchResults.length} items',
                style: TextStyle(color: _darkGrey),
              ),
            ],
          ),
        ),
      ),
      _buildProductGrid(_searchResults),
    ];
  }

  List<Widget> _buildMainContent() {
    return [
      // 🍽️ CATEGORIES SECTION
      SliverToBoxAdapter(
        child: _buildSectionHeader("Categories", "See All"),
      ),
      SliverToBoxAdapter(
        child: _buildCategoriesRow(),
      ),

      // 🔥 BEST SELLERS
      SliverToBoxAdapter(
        child: _buildSectionHeader("Best Sellers", "See All"),
      ),
      SliverToBoxAdapter(
        child: FutureBuilder<List<MenuItem>>(
          future: _bestsellersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptySection("No bestsellers available");
            }
            return _buildBestSellersGrid(snapshot.data!);
          },
        ),
      ),

      // 💚 RECOMMENDED FOR YOU
      SliverToBoxAdapter(
        child: _buildSectionHeader("Recommended for you", "See All"),
      ),
      _buildRecommendedGrid(),
    ];
  }

  // 👤 USER HEADER
  Widget _buildUserHeader() {
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data?.fullName?.split(' ').first ?? 'Guest';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good ${_getTimeBasedGreeting()}!",
                      style: TextStyle(
                        fontSize: 14,
                        color: _darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hello, $userName 👋",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryGreen.withValues(alpha:0.3)),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: _primaryGreen.withValues(alpha:0.1),
                  child: Icon(Icons.person, color: _primaryGreen, size: 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔍 SEARCH BAR
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _lightGrey,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search store...",
            hintStyle: TextStyle(color: _darkGrey),
            prefixIcon: Icon(Icons.search, color: _darkGrey),
            suffixIcon: _isSearching
                ? IconButton(
              icon: Icon(Icons.close, color: _darkGrey),
              onPressed: _clearSearch,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // 🎯 HERO BANNER
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Fresh",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Get Fresh Food",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fresh and organic food delivered to your doorstep",
                    style: TextStyle(
                      color: _darkGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Image.asset(
              "assets/images/fresh_food.png",
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.restaurant, color: _primaryGreen, size: 40),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📌 SECTION HEADER
  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            action,
            style: TextStyle(
              color: _primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🍽️ CATEGORIES ROW
  Widget _buildCategoriesRow() {
    return FutureBuilder<List<AppCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: _primaryGreen)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptySection("No categories available");
        }

        final categories = snapshot.data!;
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(AppCategory category) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: _lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getIconForCategory(category.name),
            size: 32,
            color: _primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _darkGrey,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 🔥 BEST SELLERS GRID
  Widget _buildBestSellersGrid(List<MenuItem> bestsellers) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: bestsellers.length,
        itemBuilder: (context, index) {
          final item = bestsellers[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: index == bestsellers.length - 1 ? 0 : 15),
            child: _buildProductCard(item),
          );
        },
      ),
    );
  }

  // 💚 RECOMMENDED GRID
  SliverGrid _buildRecommendedGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return FutureBuilder<List<MenuItem>>(
            future: _recommendedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildProductCardShimmer();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty || index >= snapshot.data!.length) {
                return const SizedBox();
              }
              final item = snapshot.data![index];
              return _buildProductCard(item);
            },
          );
        },
        childCount: 4, // Show 4 items initially
      ),
    );
  }

  // 🔍 SEARCH RESULTS GRID
  SliverGrid _buildProductGrid(List<MenuItem> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildProductCard(item),
          );
        },
        childCount: items.length,
      ),
    );
  }

  // 🛒 PRODUCT CARD
  Widget _buildProductCard(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT IMAGE
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _lightGrey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.fastfood, color: _darkGrey, size: 40),
                      );
                    },
                  ),
                )
                    : Center(
                  child: Icon(Icons.fastfood, color: _darkGrey, size: 40),
                ),
              ),
              if (item.isBestseller)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "BEST",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // PRODUCT DETAILS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description ?? "Fresh and delicious",
                  style: TextStyle(
                    color: _darkGrey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onAddToCart(item),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
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
    );
  }

  Widget _buildProductCardShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _lightGrey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                SizedBox(height: 4),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(height: 20),
                    SizedBox(
                      width: 30,
                      height: 30,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: _darkGrey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 🕒 HELPER METHODS
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'meals':
        return Icons.lunch_dining;
      case 'drinks':
        return Icons.local_drink;
      case 'desserts':
        return Icons.cake;
      case 'snacks':
        return Icons.fastfood;
      default:
        return Icons.restaurant_menu;
    }
  }
}