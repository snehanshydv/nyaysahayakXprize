import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF7), // Light mint background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildTopBar(),
                const SizedBox(height: 30),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildHeroImageSection(),
                const SizedBox(height: 40),
                _buildMainText(),
                const SizedBox(height: 40),
                _buildGetStartedButton(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {},
                  child: const Text("How it works", 
                    style: TextStyle(color: Color(0xFF13694F), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 40),
                _buildFooterFeatures(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _languageChip("ENGLISH", true),
              _languageChip("हिंदी", false),
            ],
          ),
        )
      ],
    );
  }

  Widget _languageChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isActive ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF13694F) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.scale, color: Colors.white, size: 40),
    );
  }

  Widget _buildHeroImageSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Image Container
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://placehold.co/600x600/png', // Replace with your scales image
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // 100% Verified Badge
        Positioned(
          top: -15,
          left: -10,
          child: _infoBadge(Icons.verified_user_outlined, "100% Verified"),
        ),
        // AI-Powered Badge
        Positioned(
          right: -10,
          top: 100,
          child: _infoBadge(Icons.bolt, "AI-Powered"),
        ),
        // Government Approved Badge
        Positioned(
          bottom: -15,
          left: 20,
          child: _infoBadge(Icons.check_circle_outline, "Government Approved"),
        ),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF13694F)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMainText() {
    return Column(
      children: [
        const Text(
          "Legal Assistance",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const Text(
          "Simplified.",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF13694F), fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Text(
          "Get instant AI legal advice, file cases securely, and connect with top-rated lawyers across India.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return Builder(
      builder: (context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D5D46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterFeatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _footerItem(Icons.headset_mic_outlined, "24/7 SUPPORT"),
        _footerItem(Icons.lock_outline, "DATA SECURED"),
        _footerItem(Icons.language, "MULTI-LINGUAL"),
      ],
    );
  }

  Widget _footerItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF13694F), size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}