import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:longtea_mobile/providers/auth_notifier.dart';
import 'package:longtea_mobile/screens/edit_profile_screen.dart';

const String kImagePath = 'assets/images/';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _calledOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_calledOnce) {
      _calledOnce = true;
      _callGetProfileInBackground();
    }
  }

  Future<void> _callGetProfileInBackground() async {
    try {
      // Fetch profile from backend and update state
      await ref.read(authProvider.notifier).fetchProfile();
    } catch (_) {
      // Silently ignore; background fetch only
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final List<Map<String, dynamic>> menuItems = [
      {
        'label': 'Edit Profile',
        'icon': Icons.edit,
        'hasArrow': true,
        'action': _navigateToEditProfile,
      },
      {
        'label': 'Order History',
        'icon': Icons.history,
        'hasArrow': true,
        'action': () => _showComingSoon('Order History'),
      },
      {
        'label': 'Manage Addresses',
        'icon': Icons.location_on,
        'hasArrow': true,
        'action': () => _showComingSoon('Manage Addresses'),
      },
      {
        'label': 'Loyalty Program',
        'icon': Icons.card_giftcard,
        'hasArrow': true,
        'action': () => _showComingSoon('Loyalty Program'),
      },
      {
        'label': 'Settings',
        'icon': Icons.settings,
        'hasArrow': true,
        'action': () => _showComingSoon('Settings'),
      },
      {
        'label': 'Help & Support',
        'icon': Icons.help_outline,
        'hasArrow': true,
        'action': () => _showComingSoon('Help & Support'),
      },
      {
        'label': 'Log Out',
        'icon': Icons.logout,
        'hasArrow': false,
        'action': _handleLogout,
        'isDestructive': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF1E2A44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.fullName ?? 'Guest',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isAuthenticated)
                          IconButton(
                            onPressed: _navigateToEditProfile,
                            icon: const Icon(Icons.edit, color: Colors.white),
                            tooltip: 'Edit Profile',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  if (isAuthenticated)
                    Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4A90E2),
                                    Color(0xFF1E2A44),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  '${kImagePath}profile.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Guest User',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ??
                                        user?.phoneNumber ??
                                        'No contact info',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (user?.role != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4A90E2,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user!.role.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4A90E2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Menu Items
                  Expanded(
                    child: ListView.separated(
                      itemCount: menuItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return _buildMenuItem(item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final bool isDestructive = item['isDestructive'] ?? false;
    final IconData icon = item['icon'] ?? Icons.arrow_forward;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item['action'] as VoidCallback?,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['label'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (item['hasArrow'])
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDestructive
                      ? Colors.red.withOpacity(0.5)
                      : const Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
