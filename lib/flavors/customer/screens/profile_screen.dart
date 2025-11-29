import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("My Account", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Replace with user image
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Anna Abrahamyan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("anna@example.com", style: TextStyle(color: Colors.grey.shade500)),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),

          // Menu Items
          _buildMenuItem(Icons.shopping_bag_outlined, "Orders"),
          _buildMenuItem(Icons.badge_outlined, "My Details"),
          _buildMenuItem(Icons.location_on_outlined, "Delivery Address"),
          _buildMenuItem(Icons.credit_card, "Payment Methods"),
          _buildMenuItem(Icons.card_giftcard, "Promo Cord"),
          _buildMenuItem(Icons.notifications_outlined, "Notifications"),
          _buildMenuItem(Icons.help_outline, "Help"),
          _buildMenuItem(Icons.info_outline, "About"),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F3F2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Color(0xFF53B175)),
                  SizedBox(width: 20),
                  Text("Log Out", style: TextStyle(color: Color(0xFF53B175), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.black),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          onTap: () {},
        ),
        const Divider(),
      ],
    );
  }
}