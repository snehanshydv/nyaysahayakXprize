import 'package:flutter/material.dart';
import 'package:nyaysahayak/services/api_service.dart';
import 'package:nyaysahayak/services/auth_service.dart';
import 'package:nyaysahayak/app/case_screen.dart';
import 'package:nyaysahayak/app/widgets/main_layout.dart';

class CasesHistoryScreen extends StatefulWidget {
  const CasesHistoryScreen({Key? key}) : super(key: key);

  @override
  _CasesHistoryScreenState createState() => _CasesHistoryScreenState();
}

class _CasesHistoryScreenState extends State<CasesHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    final uid = await AuthService.getUid();
    if (uid != null) {
      final cases = await ApiService.getChatSessions(uid);
      if (mounted) {
        setState(() {
          _cases = cases;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "Recently";
    try {
      final DateTime date = DateTime.parse(ts.toString()).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "Recently";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3,
      appBar: AppBar(
        title: const Text(
          "Chat History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey[200], height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF13694F)),
            )
          : _cases.isEmpty
          ? const Center(
              child: Text(
                "No chat history found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cases.length,
              itemBuilder: (context, index) {
                final c = _cases[index] as Map<String, dynamic>;
                final String sessionId = c['id'] ?? 'Unknown';
                final List<dynamic> sessionData = c['session_data'] ?? [];

                String preview = "Empty conversation";
                for (var msg in sessionData) {
                  if (msg is Map &&
                      msg['role'] == 'user' &&
                      msg.containsKey('content')) {
                    preview = msg['content'];
                    break;
                  }
                }

                final int msgCount = sessionData.length;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CaseScreen(restoredSessionId: sessionId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  preview,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF13694F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(c['timestamp']),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.message,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$msgCount msgs",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
