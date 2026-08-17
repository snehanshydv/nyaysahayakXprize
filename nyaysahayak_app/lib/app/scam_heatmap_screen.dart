import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nyaysahayak/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScamHeatmapScreen extends StatefulWidget {
  const ScamHeatmapScreen({super.key});

  @override
  State<ScamHeatmapScreen> createState() => _ScamHeatmapScreenState();
}

class _ScamHeatmapScreenState extends State<ScamHeatmapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _scams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchScams();
  }

  Future<void> _fetchScams() async {
    final scams = await ApiService.getNearbyScams(20.5937, 78.9629);
    if (mounted) {
      setState(() {
        _scams = scams;
        _loading = false;
      });
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  void _showScamDetails(Map<String, dynamic> scam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scam['scam_type']?.toString().toUpperCase() ?? 'SCAM',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getRiskColor(scam['risk_level']?.toString() ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getRiskColor(scam['risk_level']?.toString() ?? '').withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${scam['risk_level']?.toString() ?? 'Medium'} Risk',
                          style: TextStyle(
                            color: _getRiskColor(scam['risk_level']?.toString() ?? ''),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                scam['title']?.toString() ?? 'Security Alert',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD0E3FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_rounded, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Intelligence Report',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scam['description']?.toString() ?? 'Local authorities report active fraudulent activity in this area. Residents are advised to exercise extreme caution.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _infoBadge(Icons.location_on_rounded, scam['city']?.toString() ?? 'Delhi NCR'),
                  const SizedBox(width: 12),
                  _infoBadge(
                    Icons.calendar_today_rounded,
                    scam['timestamp'] != null 
                        ? scam['timestamp'].toString().split('T')[0] 
                        : 'Recent',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13694F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Acknowledge Risk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scam Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF13694F)))
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 4.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.maptiler.com/maps/${dotenv.env['MAPTILER_STYLE'] ?? 'openstreetmap'}/256/{z}/{x}/{y}.png?key=${dotenv.env['MAPTILER_KEY']}',
                  userAgentPackageName: 'com.example.nyaysahayak',
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('Powered by MapTiler & OpenStreetMap'),
                  ],
                ),
                MarkerLayer(
                  markers: _scams.map((scam) {
                    return Marker(
                      point: LatLng(
                        (scam['lat'] as num?)?.toDouble() ?? 0.0,
                        (scam['lon'] as num?)?.toDouble() ?? 0.0,
                      ),
                      width: 28,  // A bit larger hit area
                      height: 28, // Hit area
                      child: GestureDetector(
                        onTap: () => _showScamDetails(scam as Map<String, dynamic>),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getRiskColor(scam['risk_level']?.toString() ?? ''),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRiskColor(scam['risk_level']?.toString() ?? '').withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
