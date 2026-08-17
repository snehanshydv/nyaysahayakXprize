import 'package:flutter/material.dart';
import 'package:nyaysahayak/services/api_service.dart';
import 'package:nyaysahayak/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:nyaysahayak/app/widgets/main_layout.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  String selectedCategory = "Family Law";
  String selectedLanguage = "English";
  bool _submitting = false;
  String? _error;
  String? _success;

  final _descCtrl = TextEditingController();
  final _uuid = const Uuid();

  final List<String> categories = [
    "Family Law",
    "Property Dispute",
    "Criminal Defense",
    "Employment Issues",
    "Consumer Rights",
    "Cyber Crime",
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descCtrl.text.trim();
    if (description.length < 20) {
      setState(
        () => _error =
            'Please provide a more detailed description (at least 20 characters).',
      );
      return;
    }

    final uid = await AuthService.getUid();
    if (uid == null || uid.isEmpty) {
      setState(() => _error = 'You must be logged in to file a case.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    final caseId = _uuid.v4();

    final report = {
      'incident_type': selectedCategory,
      'description': description,
      'preferred_language': selectedLanguage,
      'risk_level': 'Medium',
      'status': 'pending',
    };

    final sessionData = [
      {
        'role': 'user',
        'content': 'I need help with a $selectedCategory issue: $description',
      },
    ];

    try {
      final ok = await ApiService.saveCase(
        uid: uid,
        caseId: caseId,
        structuredReport: report,
        sessionData: sessionData,
      );

      if (ok) {
        setState(() {
          _success =
              'Your case has been filed successfully! Case ID: ${caseId.substring(0, 8).toUpperCase()}. Our AI will review your case and match you with a lawyer.';
          _descCtrl.clear();
        });
      } else {
        setState(() => _error = 'Failed to file case. Please try again.');
      }
    } catch (e) {
      setState(
        () =>
            _error = 'Cannot connect to server. Please check your connection.',
      );
    }

    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "File a Case",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopStatusInfo(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepperIndicator(),
                  const SizedBox(height: 32),
                  const Text(
                    "What type of legal help do you need?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                  const SizedBox(height: 32),
                  const Text(
                    "Describe the incident or situation",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDescriptionBox(),
                  const SizedBox(height: 16),
                  _buildExpertTip(),
                  const SizedBox(height: 32),
                  const Text(
                    "Preferred Language for Proceedings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageSelector(),
                  const SizedBox(height: 32),
                  if (_error != null)
                    _buildFeedbackBanner(_error!, isError: true),
                  if (_success != null)
                    _buildFeedbackBanner(_success!, isError: false),
                  const SizedBox(height: 16),
                  _buildNextButton(),
                  const SizedBox(height: 16),
                  if (_success != null)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF13694F),
                        ),
                        label: const Text(
                          "Open AI Chat for this Case",
                          style: TextStyle(
                            color: Color(0xFF13694F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF13694F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/cases'),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red[800] : Colors.green[800],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: Colors.black54),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Auto-Saved",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.black54),
                SizedBox(width: 6),
                Text(
                  "AES-256 ENCRYPTED CONNECTION",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Row(
      children: [
        _stepCircle(Icons.description, "Details", true),
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
        _stepCircle(Icons.upload_file, "Documents", false),
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
        _stepCircle(Icons.check_circle_outline, "Review", false),
      ],
    );
  }

  Widget _stepCircle(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF13694F) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[300]!,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF13694F) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) {
        bool isSelected = selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => selectedCategory = cat),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF13694F) : Colors.grey[200]!,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              cat,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF13694F) : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _descCtrl,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: "Provide a detailed description of the events...",
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildExpertTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF13694F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Expert Tip: Be Specific",
                  style: TextStyle(
                    color: Color(0xFF13694F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mention dates, names of parties involved, and the specific outcome you are seeking. This helps our AI & lawyers evaluate your case faster.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    List<String> langs = ["English", "Hindi", "Other"];
    return Row(
      children: langs.map((lang) {
        bool isSelected = selectedLanguage == lang;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => selectedLanguage = lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF13694F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
              child: Text(
                lang,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF13694F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Submit Case",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
      ),
    );
  }
}
