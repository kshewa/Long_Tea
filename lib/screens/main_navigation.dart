import 'package:flutter/material.dart';
import 'package:longtea_mobile/screens/preorder_screen.dart';

import 'home_screen.dart';
import 'loyalty_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart'; // Add this import

class MainNavigation extends StatefulWidget {
  final int initialTab;

  const MainNavigation({super.key, this.initialTab = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PreOrderScreen(preOrders: []),
    const CartScreen(),
    const LoyaltyScreen(),
    const FavoriteScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: const Color(0xFF6B7280),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag, size: 24),
              label: 'Preorders',
            ),
            BottomNavigationBarItem(
              // Add Cart item
              icon: Icon(Icons.shopping_cart, size: 24),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star, size: 24),
              label: 'Loyalty',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite, size: 24),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
