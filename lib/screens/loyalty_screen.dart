import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int currentProgress = 7; // 7 out of 10 cups filled
  final int totalCups = 10;
  bool showAffiliateProgram = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: showAffiliateProgram
          ? _buildAffiliateProgram()
          : _buildLoyaltyProgram(),
    );
  }

  Widget _buildLoyaltyProgram() {
    return Column(
      children: [
        // Header Section
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            AssetImage('assets/images/profile.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Betty Tesfaye',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: const [
                                Text(
                                  'Dembel, Addis Ababa',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.arrow_back_ios,
                          color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Loyalty',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content Section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Loyalty Card
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                                text: 'Buy ',
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: '10 ',
                                style: TextStyle(color: Colors.red)),
                            TextSpan(
                                text: 'Get ',
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: '1 ',
                                style: TextStyle(color: Colors.red)),
                            TextSpan(
                                text: ' For Free',
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cups + Progress inside styled container
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: currentProgress >= totalCups
                              ? Colors.red
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        
                        child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               
                          children: [
                               const SizedBox(width: 3),

                           
                            Row(
                              children: List.generate(totalCups, (index) {
                                bool isFilled = index < currentProgress;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  child: Image.asset(
                                    isFilled
                                        ? 'assets/images/cup_filled.png'
                                        : 'assets/images/cup_empty.png',
                                 
                                    height: 32,
                                  ),
                                );
                              }),
                            ),
                                 const SizedBox(width: 2),
                      Text(
                              '$currentProgress/$totalCups',
                              style: const TextStyle(
                                fontSize: 26,
                                height: 1.7,
                              
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Claim Reward Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onClaimPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentProgress >= totalCups
                                ? Colors.red
                                : Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Claim Reward',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered QR Code
                Expanded(
                  child: Center(
                    child: QrImageView(
                      data:
                          'LOYALTY_USER_${DateTime.now().millisecondsSinceEpoch}',
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: const Color(0xFFB3D9FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Second Page
  Widget _buildAffiliateProgram() {
    return Center(
      child: Text("Affiliate Page"), // keep simple for now
    );
  }

  void _onClaimPressed() {
    if (currentProgress >= totalCups) {
      _claimReward();
    } else {
      final remaining = totalCups - currentProgress;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need $remaining more to claim your reward.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _claimReward() {
    setState(() {
      showAffiliateProgram = true;
    });
  }
}
