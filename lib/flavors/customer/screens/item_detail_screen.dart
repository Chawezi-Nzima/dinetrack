import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/menu_models.dart';

class ItemDetailScreen extends StatelessWidget {
  final MenuItem item;
  final Function(MenuItem, int) onAddToCart;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl ?? 'https://via.placeholder.com/300';

    return _ItemDetailContent(
      item: item,
      imageUrl: imageUrl,
      onAddToCart: onAddToCart,
    );
  }
}

class _ItemDetailContent extends StatefulWidget {
  final MenuItem item;
  final String imageUrl;
  final Function(MenuItem, int) onAddToCart;

  const _ItemDetailContent({
    required this.item,
    required this.imageUrl,
    required this.onAddToCart,
  });

  @override
  State<_ItemDetailContent> createState() => _ItemDetailContentState();
}

class _ItemDetailContentState extends State<_ItemDetailContent> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final price = item.price;
    final imageUrl = widget.imageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Header Image Area with curved bottom
          Container(
            width: double.infinity,
            height: 250,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3F2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.fastfood, size: 80, color: Colors.grey);
                },
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.description ?? "Fresh and delicious",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Quantity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.grey),
                          onPressed: () {
                            if (_qty > 1) setState(() => _qty--);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_qty',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF53B175)),
                          onPressed: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                    Text(
                      '${(price * _qty).toStringAsFixed(0)} MWK',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  "Product Detail",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description ?? 'No description available for this product. It is fresh and organic.',
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),

                const SizedBox(height: 20),

                // Nutrition Information (if available)
                if (item.description?.isNotEmpty ?? false) ...[
                  const Text(
                    "Nutrition Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Fresh and organic ingredients. Perfect for a healthy diet.",
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                ],

                // Similar Products Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Similar Products",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "See all",
                      style: TextStyle(color: Color(0xFF53B175)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Scroll Placeholder for Similar Products
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (ctx, i) => Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Bottom Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAddToCart(widget.item, _qty);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B175),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text(
                  "Add To Basket",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}