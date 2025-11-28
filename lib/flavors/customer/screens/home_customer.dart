import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/menu_models.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Color _primaryBlue = const Color(0xFF1A73E8);
  final Color _accentGreen = const Color(0xFF2ECC71);
  final Color _lightGrey = const Color(0xFFF7F7F7);

  Future<List<AppCategory>> _categoriesFuture = Future.value([]);
  Future<List<MenuItem>> _bestsellersFuture = Future.value([]);
  Future<List<MenuItem>> _recommendedFuture = Future.value([]);
  Future<UserProfile?> _userProfileFuture = Future.value(null);

  final TextEditingController _searchController = TextEditingController();
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _categoriesFuture = _supabaseService.getCategories();
      _bestsellersFuture = _supabaseService.getBestsellers();
      _recommendedFuture = _supabaseService.getRecommended();
      _userProfileFuture = _supabaseService.getCurrentUserProfile();
    });
  }

  void _refreshData() {
    _loadData(); // Already calls setState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // 👤 USER WELCOME & PROFILE SECTION
            _buildUserHeader(),

            // 📱 MAIN CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔍 SEARCH BAR
                      _buildSearchBar(),
                      const SizedBox(height: 24),

                      // 🍰 HERO SECTION
                      _buildHeroBanner(),
                      const SizedBox(height: 24),

                      // 📌 Categories Section
                      _buildSectionHeader("Categories", "See All", onSeeAll: () {}),
                      const SizedBox(height: 16),
                      _buildCategoriesRow(),

                      const SizedBox(height: 24),

                      // 💸 Promotion Section
                      _buildPromoSection(),

                      const SizedBox(height: 24),

                      // ⭐ BEST SELLERS
                      _buildSectionHeader("Best Sellers", "View All", onSeeAll: () {}),
                      const SizedBox(height: 16),
                      _buildBestSellersSection(),

                      const SizedBox(height: 24),

                      // 🥗 Recommended Section
                      _buildSectionHeader("Recommended for you", "More", onSeeAll: () {}),
                      const SizedBox(height: 16),
                      _buildRecommendedSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ----------------------------------------------------------
  // 👤 USER HEADER WITH WELCOME
  Widget _buildUserHeader() {
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data?.fullName ?? 'Guest';
        final dineCoins = snapshot.data?.dineCoinsBalance ?? 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good ${_getTimeBasedGreeting()}!",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hello, $userName 👋",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "DineCoins: ${dineCoins.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _primaryBlue.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: _primaryBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔍 SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search menu items...",
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          if (value.length > 2) {
            // Implement search functionality
            _supabaseService.searchMenuItems(value);
          }
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔵 HERO BANNER
  Widget _buildHeroBanner() {
    return GestureDetector(
      onTap: () {
        // Navigate to special offers
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryBlue.withValues(alpha:0.9), _primaryBlue],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withValues(alpha:0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
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
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "🔥 Today's Special",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chef's Special Healthy Meal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fresh, organic ingredients prepared with love. Limited time offer!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Order Now →",
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.white.withValues(alpha:0.2),
                child: Icon(Icons.local_fire_department, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 📌 SECTION HEADER
  Widget _buildSectionHeader(String title, String action, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              action,
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 🍽️ CATEGORIES ROW
  Widget _buildCategoriesRow() {
    return FutureBuilder<List<AppCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No categories available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final categories = snapshot.data!;
        final categoryColors = [
          _primaryBlue,
          Colors.orange,
          Colors.pink,
          Colors.purple,
          Colors.red,
        ];

        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = categoryColors[index % categoryColors.length];

              return GestureDetector(
                onTap: () {
                  // Navigate to category
                },
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha:0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForCategory(category.name),
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 💸 PROMO BANNER
  Widget _buildPromoSection() {
    return GestureDetector(
      onTap: () {
        // Navigate to promotions
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_accentGreen.withValues(alpha:0.9), _accentGreen],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentGreen.withValues(alpha:0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "SPECIAL OFFER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "20% OFF",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "On selected meals this week! Don't miss out!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.local_offer, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ⭐ BEST SELLERS SECTION
  Widget _buildBestSellersSection() {
    return FutureBuilder<List<MenuItem>>(
      future: _bestsellersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'No bestsellers available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final bestsellers = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bestsellers.length,
          itemBuilder: (context, index) {
            final item = bestsellers[index];
            return _buildMenuItemCard(item);
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🥗 RECOMMENDED SECTION
  Widget _buildRecommendedSection() {
    return FutureBuilder<List<MenuItem>>(
      future: _recommendedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
              );
            },
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'No recommendations available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final recommendedItems = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendedItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = recommendedItems[index];
            return _buildMenuItemGridCard(item);
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🍽️ MENU ITEM CARD (for bestsellers)
  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl != null
                    ? Image.network(
                  item.imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: _lightGrey,
                      child: Icon(Icons.fastfood, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  width: 120,
                  height: 120,
                  color: _lightGrey,
                  child: Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "BESTSELLER",
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      onPressed: () {
                        _supabaseService.addToCart(item.id, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${item.name} to cart'),
                            backgroundColor: _accentGreen,
                          ),
                        );
                      },
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(color: Colors.white),
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

  // ----------------------------------------------------------
  // 🍽️ MENU ITEM GRID CARD (for recommended)
  Widget _buildMenuItemGridCard(MenuItem item) {
    return GestureDetector(
      onTap: () {
        // Navigate to item details
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ITEM IMAGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: item.imageUrl != null
                      ? Image.network(
                    item.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: _lightGrey,
                        child: Icon(Icons.fastfood, color: Colors.grey),
                      );
                    },
                  )
                      : Container(
                    height: 120,
                    color: _lightGrey,
                    child: Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
                if (item.preparationTime != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '${item.preparationTime} min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ITEM DETAILS
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _supabaseService.addToCart(item.id, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${item.name} to cart'),
                            backgroundColor: _accentGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ⬇️ BOTTOM NAVIGATION BAR
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
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
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
            // Handle navigation
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primaryBlue,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
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