import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;

  const MainLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    this.appBar,
    this.backgroundColor = const Color(0xFFF9FBFB),
  });

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    const routes = ['/home', '/search', '/file', '/history'];
    if (index >= routes.length) return;

    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      if (currentIndex == 0) {
        Navigator.pushNamed(context, routes[index]);
      } else {
        Navigator.pushReplacementNamed(context, routes[index]);
      }
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF13694F) : Colors.grey[400]!;
    return InkWell(
      onTap: () => _onNavTap(context, index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // currentIndex == -1 means the CaseScreen is using this layout directly.
    // Hide the FAB (already on cases/chat) and show all 4 nav items evenly.
    final isCasesScreen = currentIndex == -1;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      resizeToAvoidBottomInset: isCasesScreen,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isCasesScreen
          ? null
          : FloatingActionButton(
              elevation: 4,
              backgroundColor: const Color(0xFF13694F),
              onPressed: () => Navigator.pushNamed(context, '/cases'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
      bottomNavigationBar: BottomAppBar(
        shape: isCasesScreen ? null : const CircularNotchedRectangle(),
        notchMargin: isCasesScreen ? 0 : 8.0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isCasesScreen
                ? [
                    _buildNavItem(context, 0, Icons.home_filled, "Home"),
                    _buildNavItem(context, 1, Icons.search, "Search"),
                    _buildNavItem(context, 2, Icons.folder_outlined, "File"),
                    _buildNavItem(context, 3, Icons.history, "History"),
                  ]
                : [
                    _buildNavItem(context, 0, Icons.home_filled, "Home"),
                    _buildNavItem(context, 1, Icons.search, "Search"),
                    const SizedBox(width: 48), // Space for FAB
                    _buildNavItem(context, 2, Icons.folder_outlined, "File"),
                    _buildNavItem(context, 3, Icons.history, "History"),
                  ],
          ),
        ),
      ),
    );
  }
}
