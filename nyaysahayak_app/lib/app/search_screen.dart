import 'package:flutter/material.dart';
import 'package:nyaysahayak/models/models.dart';
import 'package:nyaysahayak/services/api_service.dart';
import 'package:nyaysahayak/app/widgets/main_layout.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<LawyerModel> _lawyers = [];
  bool _loading = true;
  bool _searching = false;
  String _activeFilter = "All Services";
  final List<String> _filters = [
    "All Services",
    "Family Law",
    "Property",
    "Criminal",
    "Cyber",
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllLawyers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAllLawyers() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getLawyers();
      setState(() {
        _lawyers = raw
            .whereType<Map<String, dynamic>>()
            .map(LawyerModel.fromJson)
            .toList();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _fetchAllLawyers();
      return;
    }
    setState(() => _searching = true);
    try {
      final raw = await ApiService.searchLawyers(query: query);
      setState(() {
        _lawyers = raw
            .whereType<Map<String, dynamic>>()
            .map(LawyerModel.fromJson)
            .toList();
      });
    } catch (_) {}
    setState(() => _searching = false);
  }

  List<LawyerModel> get _filtered {
    if (_activeFilter == "All Services") return _lawyers;
    return _lawyers
        .where(
          (l) => l.specialization.toLowerCase().contains(
            _activeFilter.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Find Legal Help",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterBar(),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[200], height: 1),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF13694F)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildSectionHeader(),
                    const SizedBox(height: 20),
                    if (_searching)
                      const CircularProgressIndicator(color: Color(0xFF13694F))
                    else if (_filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filtered.map((l) => LawyerCard(lawyer: l)),
                    const SizedBox(height: 20),
                    _buildTrustedAssistanceCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: "Search lawyers, services, or topics...",
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF13694F)),
              onPressed: () => _search(_searchCtrl.text),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterIcon(),
          ..._filters.map((f) => _filterChip(f, f == _activeFilter)),
        ],
      ),
    );
  }

  Widget _filterIcon() {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 8, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.tune, size: 20, color: Colors.black87),
    );
  }

  Widget _filterChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 8, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF13694F) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "TOP EXPERTS (${_filtered.length})",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
            color: Colors.black54,
          ),
        ),
        const Text(
          "View Map",
          style: TextStyle(
            color: Color(0xFF13694F),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No lawyers found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term or filter.",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedAssistanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EAE2)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD1EAE2),
            child: Icon(Icons.verified_outlined, color: Color(0xFF13694F)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Trusted Assistance",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "All lawyers on NyaySahayak undergo a strict 3-step verification process to ensure Bar Council compliance.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lawyer Card Widget ───────────────────────────────────────────────────────

class LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  const LawyerCard({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFF13694F),
                    backgroundImage: lawyer.avatar.startsWith('http')
                        ? NetworkImage(lawyer.avatar)
                        : null,
                    child: lawyer.avatar.startsWith('http')
                        ? null
                        : Text(
                            lawyer.name.isNotEmpty ? lawyer.name[0] : 'L',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: lawyer.isOnline
                            ? Colors.green
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lawyer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF13694F),
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      lawyer.specialization,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.history, color: Colors.grey, size: 14),
                        Text(
                          " ${lawyer.experience}+ Years",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (lawyer.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 14,
                          ),
                          Text(
                            " ${lawyer.location}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CONSULTATION FEE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "₹${lawyer.hourlyRate}/hr",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13694F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "Consult",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
