class AppCategory {
  final String id;
  final String establishmentId;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;

  AppCategory({
    required this.id,
    required this.establishmentId,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.isActive,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isBestseller;
  final bool isRecommended;
  final double rating;
  final int? preparationTime;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.isBestseller,
    required this.isRecommended,
    required this.rating,
    this.preparationTime,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isRecommended: json['is_recommended'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      preparationTime: json['preparation_time'] as int?,
    );
  }

  String get formattedPrice {
    return '${price.toStringAsFixed(0)} MWK';
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String userType;
  final double dineCoinsBalance;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.userType,
    required this.dineCoinsBalance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      userType: json['user_type'] as String,
      dineCoinsBalance: (json['dine_coins_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}