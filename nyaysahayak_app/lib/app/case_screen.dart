import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nyaysahayak/models/models.dart';
import 'package:nyaysahayak/services/api_service.dart';
import 'package:nyaysahayak/services/auth_service.dart';
import 'package:nyaysahayak/app/widgets/main_layout.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'chat_features.dart';

class CaseScreen extends StatefulWidget {
  final String? restoredSessionId;
  const CaseScreen({super.key, this.restoredSessionId});

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  String _uid = '';
  String _userName = '';
  String? _sessionId;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _activeAgent;

  Map<String, dynamic>? _structuredReport;
  List<dynamic> _suggestedActions = [];
  List<dynamic> _recommendedLawyers = [];
  List<dynamic> _recommendedSahayaks = [];
  List<dynamic> _nodalGuideProfiles = [];
  String? _pdfUrl;
  String? _currentCaseId;
  bool _questionFlowActive = false;

  // Selected contexts from checklist
  List<String> _selectedContexts = [];

  // Voice feature state
  bool _isDictationMode = true;
  bool _isRecording = false;
  bool _isPlayingTTS = false;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  // Silence detection state
  Timer? _silenceTimer;
  DateTime? _recordingStartTime;
  DateTime? _lastSoundTime;
  bool _hasStartedSpeaking = false;
  static const double _silenceThreshold = -10.0; // dB
  static const int _silenceDurationMs = 1700;
  static const int _maxRecordingDurationMs = 20000;
  static const int _amplitudeCheckIntervalMs = 100;

  @override
  void initState() {
    super.initState();
    _loadUser();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlayingTTS = false);
        // Seamlessly continue conversation loop
        if (!_isDictationMode && !_isRecording) {
          _toggleRecording();
        }
      }
    });
  }

  Future<void> _loadUser() async {
    final uid = await AuthService.getUid();
    final name = await AuthService.getName();
    setState(() {
      _uid = uid ?? '';
      _userName = name ?? 'User';
      _sessionId = widget.restoredSessionId ?? _uuid.v4();
    });

    if (widget.restoredSessionId != null && uid != null) {
      _loadHistory(uid, widget.restoredSessionId!);
    }
  }

  Future<void> _loadHistory(String uid, String sessionId) async {
    try {
      final history = await ApiService.getChatHistory(uid, sessionId);
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          for (var msgData in history) {
            final roleStr = msgData['role'] as String? ?? 'user';
            final content = msgData['content'] as String? ?? '';
            final agent = msgData['agent'] as String?;
            final options = msgData['options'] as List<dynamic>?;
            if (options != null) {
              _suggestedActions = options;
            }
            _messages.add(ChatMessage(
              id: _uuid.v4(),
              role: roleStr == 'user' ? MessageRole.user : MessageRole.assistant,
              content: content,
              timestamp: DateTime.now(),
              agent: agent,
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Failed to load history: $e");
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _messageCtrl.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _messageCtrl.clear();
    setState(() {
      _structuredReport = null;
      _suggestedActions = [];
      _recommendedLawyers = [];
      _recommendedSahayaks = [];
      _nodalGuideProfiles = [];
      _pdfUrl = null;
      _currentCaseId = null;
      _questionFlowActive = false;
      _selectedContexts = []; // Clear selected contexts on new message
    });

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isStreaming = true;
      _activeAgent = null;
    });
    _scrollToBottom();

    // Add a placeholder assistant message that will be built up
    final assistantId = _uuid.v4();
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(assistantMsg));

    // Build session history from current messages (excluding the blank placeholder)
    final history = _messages
        .where((m) => m.content.isNotEmpty && m.id != assistantId)
        .map((m) => m.toJson())
        .toList();

    // Stream the response
    final stream = ApiService.streamChat(
      query: text,
      userId: _uid,
      userName: _userName,
      sessionId: _sessionId,
      sessionHistory: history,
    );

    await for (final event in stream) {
      final type = event['type'] as String?;
      if (type == 'answer') {
        final chunk = event['content'] as String? ?? '';
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == assistantId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              content: _messages[idx].content + chunk,
            );
          }
        });
        _scrollToBottom();
      } else if (type == 'agent_start') {
        setState(() {
          _activeAgent = event['agent'] as String?;
          final idx = _messages.indexWhere((m) => m.id == assistantId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(agent: _activeAgent);
          }
        });
      } else if (type == 'data') {
        setState(() {
          _structuredReport = event['structured_report'];
          _suggestedActions = event['suggested_actions'] ?? [];
          if (event['case_id'] != null) _currentCaseId = event['case_id'];
        });
        _scrollToBottom();
      } else if (type == 'lawyer_recommendations') {
        setState(() {
          _recommendedLawyers = event['lawyers'] ?? [];
        });
        _scrollToBottom();
      } else if (type == 'sahayak_recommendations') {
        setState(() {
          _recommendedSahayaks = event['sahayaks'] ?? [];
        });
        _scrollToBottom();
      } else if (type == 'nodal_guide_panel') {
        setState(() {
          _nodalGuideProfiles = event['profiles'] ?? [];
        });
        _scrollToBottom();
      } else if (type == 'pdf_ready') {
        setState(() {
          _pdfUrl = event['pdf_url'];
        });
        _scrollToBottom();
      } else if (type == 'pending_questions') {
        setState(() {
          _questionFlowActive = true;
        });
      } else if (type == 'error') {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == assistantId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              content: '⚠️ ${event['content']}',
              isStreaming: false,
            );
          }
        });
        break;
      }
    }

    // Mark streaming done
    setState(() {
      _isStreaming = false;
      _activeAgent = null;
      final idx = _messages.indexWhere((m) => m.id == assistantId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(isStreaming: false);
      }
    });
    _scrollToBottom();

    // Sync chat history to backend
    if (_uid.isNotEmpty && _sessionId != null) {
      final sessionData = _messages
          .where((m) => m.content.isNotEmpty)
          .map((m) => m.toJson())
          .toList();
      ApiService.syncChatHistory(
        uid: _uid,
        sessionId: _sessionId!,
        sessionData: sessionData,
      );
    }

    // Trigger TTS if in Conversation Mode
    if (!_isDictationMode) {
      final idx = _messages.indexWhere((m) => m.id == assistantId);
      if (idx != -1) {
        final text = _messages[idx].content;
        await _playTTS(text);
      }
    }
  }

  Future<void> _playTTS(String rawText) async {
    // Basic text cleanup for reading aloud
    final cleanText = rawText
        .replaceAll(RegExp(r'https?://[^\s]+'), '')
        .replaceAll(RegExp(r'<[^>]*>?'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\{.*?\}'), '')
        .replaceAll(RegExp(r'[*_#`~>-]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    if (cleanText.isEmpty) {
      // If empty, auto-restart recording
      if (!_isDictationMode) {
        _toggleRecording();
      }
      return;
    }

    setState(() => _isPlayingTTS = true);

    try {
      final bytes = await ApiService.synthesizeAudio(cleanText);
      if (bytes != null && bytes.isNotEmpty) {
        await _audioPlayer.play(BytesSource(bytes));
      } else {
        throw Exception("Empty audio bytes");
      }
    } catch (e) {
      print("TTS Error: $e");
      setState(() => _isPlayingTTS = false);
      if (!_isDictationMode) {
        _toggleRecording();
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_pdfUrl == null) return;

    try {
      // Step 1: Let user pick a location/folder
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // User cancelled the picker
        return;
      }

      // Show a snackbar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Step 2: Set filename
      final fileName = "case_report_${_currentCaseId ?? DateTime.now().millisecondsSinceEpoch}.pdf";
      final savePath = "$selectedDirectory/$fileName";

      // Step 3: Download using Dio
      final dio = Dio();
      await dio.download(
        _pdfUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint("${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      // Check if file exists
      if (await File(savePath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved to $fileName'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save file: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _stopTTS() {
    _audioPlayer.stop();
    setState(() => _isPlayingTTS = false);
  }

  void _handleChecklistSelect(String item) {
    if (!_selectedContexts.contains(item)) {
      setState(() {
        _selectedContexts.add(item);
      });
      // Show feedback that item was added
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to context: $item'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  void _removeContext(String context) {
    setState(() {
      _selectedContexts.remove(context);
    });
  }

  void _showVoiceModeDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice Input Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to use voice input',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // Dictation Mode Option
              GestureDetector(
                onTap: () {
                  setState(() => _isDictationMode = true);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDictationMode ? const Color(0xFFE6F0ED) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDictationMode ? const Color(0xFF00634B) : Colors.grey[300]!,
                      width: _isDictationMode ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isDictationMode ? const Color(0xFF00634B) : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: _isDictationMode ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dictation Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Voice is converted to text for you to edit before sending.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isDictationMode)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00634B),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Conversation Mode Option
              GestureDetector(
                onTap: () {
                  setState(() => _isDictationMode = false);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: !_isDictationMode ? const Color(0xFFE6F0ED) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isDictationMode ? const Color(0xFF00634B) : Colors.grey[300]!,
                      width: !_isDictationMode ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !_isDictationMode ? const Color(0xFF00634B) : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: !_isDictationMode ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conversation Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hands-free voice chat. AI speaks back and listens automatically.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isDictationMode)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00634B),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndProcess();
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        // Initialize silence detection
        _recordingStartTime = DateTime.now();
        _lastSoundTime = DateTime.now();
        _hasStartedSpeaking = false;

        // Start periodic amplitude checking
        _silenceTimer?.cancel();
        _silenceTimer = Timer.periodic(
          const Duration(milliseconds: _amplitudeCheckIntervalMs),
          (_) => _checkSilence(),
        );

        setState(() => _isRecording = true);
      }
    }
  }

  void _checkSilence() async {
    if (!_isRecording || _recordingStartTime == null) return;

    final now = DateTime.now();

    // Check max duration (20 seconds)
    if (now.difference(_recordingStartTime!).inMilliseconds >= _maxRecordingDurationMs) {
      await _stopRecordingAndProcess();
      return;
    }

    // Get current amplitude
    final amp = await _audioRecorder.getAmplitude();
    final currentDb = amp.current;

    if (currentDb > _silenceThreshold) {
      // Sound detected
      if (!_hasStartedSpeaking) {
        debugPrint("Speech detected, starting silence countdown...");
        _hasStartedSpeaking = true;
      }
      _lastSoundTime = now;
    } else if (_hasStartedSpeaking) {
      // Check for silence duration
      final silenceDuration = now.difference(_lastSoundTime!).inMilliseconds;
      if (silenceDuration > _silenceDurationMs) {
        debugPrint("Silence auto-stop triggered (${silenceDuration}ms)");
        await _stopRecordingAndProcess();
      }
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    // Cancel silence timer
    _silenceTimer?.cancel();
    _silenceTimer = null;

    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (path != null) {
      setState(() {
        _messageCtrl.text = "Transcribing...";
      });

      final transcribedText = await ApiService.transcribeAudio(path);

      if (transcribedText != null && transcribedText.trim().isNotEmpty) {
        _messageCtrl.text = transcribedText.trim();

        if (!_isDictationMode) {
          _sendMessage();
        } else {
          // Dictation mode updates text, user reviews/edits
          setState(() {});
        }
      } else {
        // Fallback if transcription comes back empty or fails
        setState(() {
          _messageCtrl.text = "";
        });
        // In conversation mode, retry after error
        if (!_isDictationMode) {
          debugPrint("Empty transcription, retrying conversation mode...");
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && !_isRecording) {
              _toggleRecording();
            }
          });
        }
      }
    }
  }

  Widget _buildVoiceInputToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isStreaming ? null : _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red[500] : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording
                        ? Colors.white
                        : const Color(0xFF00634B),
                    size: 20,
                  ),
                  if (!_isRecording && !_isDictationMode)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green[500],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (_isRecording || _isStreaming) ? null : _showVoiceModeDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                _isDictationMode
                    ? Icons.text_fields
                    : Icons.chat_bubble_outline,
                color: (_isRecording || _isStreaming)
                    ? Colors.grey[300]
                    : Colors.grey[500],
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // cases is not in the standard nav index
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isLast = i == _messages.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: msg.role == MessageRole.user
                            ? _buildUserMessage(msg)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAssistantMessage(msg, isLast),
                                  if (isLast && _recommendedLawyers.isNotEmpty)
                                    LawyerPanel(lawyers: _recommendedLawyers),
                                  if (isLast && _recommendedSahayaks.isNotEmpty)
                                    SahayakPanel(
                                      sahayaks: _recommendedSahayaks,
                                    ),
                                  if (isLast && _nodalGuideProfiles.isNotEmpty)
                                    NodalGuidePanel(
                                      profiles: _nodalGuideProfiles,
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
          if (_activeAgent != null) _buildAgentIndicator(),
          _buildBottomActionArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "AI Legal Assistant",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: Colors.black),
          onPressed: () {
            setState(() {
              _messages.clear();
              _sessionId = _uuid.v4();
            });
          },
          tooltip: 'New Session',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: Colors.grey[200], height: 1),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1FAF7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statusBadge(
            "AI Active",
            const Color(0xFFD1EAE2),
            const Color(0xFF13694F),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Session: ${_sessionId?.substring(0, 8) ?? '...'}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          if (_isStreaming)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF13694F),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF13694F),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "NyaySahayak AI",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Describe your legal issue and our AI will guide you through the process, connect you with lawyers, and help file your case.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _suggestionChip("I was cheated online"),
                _suggestionChip("Property dispute with neighbour"),
                _suggestionChip("Domestic violence help"),
                _suggestionChip("Know my consumer rights"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageCtrl.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FAF7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1EAE2)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF13694F),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(ChatMessage msg, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF13694F),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.agent != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AgentChip(agent: msg.agent!),
                  ),
                if (msg.content.isEmpty && msg.isStreaming)
                  _buildTypingIndicator()
                else
                  MarkdownBody(
                    data: msg.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      strong: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                      code: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        backgroundColor: Colors.orange[50],
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                      h1: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      blockquote: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isLast && _structuredReport != null)
                  StructuredReportView(
                    report: _structuredReport!,
                    onChecklistSelect: _handleChecklistSelect,
                  ),
                if (isLast && _suggestedActions.isNotEmpty)
                  ActionButtons(
                    actions: _suggestedActions,
                    onSelect: (payload) {
                      _messageCtrl.text = payload;
                      _sendMessage();
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildUserMessage(ChatMessage msg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF13694F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, color: Colors.white70, size: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: Duration(milliseconds: 400 + i * 200),
          margin: const EdgeInsets.only(right: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF13694F),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF1FAF7),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF13694F),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Processing with ${_activeAgent ?? 'AI'} agent...",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF13694F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pdfUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Case Document Generated!',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _downloadPDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                    ),
                    child: const Text(
                      'Download',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _actionChip(Icons.upload_file_outlined, "Upload Evidence"),
                const SizedBox(width: 10),
                _actionChip(Icons.phone_outlined, "Call Lawyer"),
                const SizedBox(width: 10),
                _actionChip(Icons.history, "Timeline"),
              ],
            ),
          ),
          // Selected Context Badges
          if (_selectedContexts.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedContexts.map((ctx) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F0ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00634B).withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ctx.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00634B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeContext(ctx),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Color(0xFF00634B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageCtrl,
                      enabled: !_isStreaming && !_isRecording,
                      maxLines: null,
                      onChanged: (text) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _isRecording
                            ? "Listening..."
                            : "Describe your legal issue...",
                        hintStyle: const TextStyle(fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_messageCtrl.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: _isStreaming ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isStreaming
                            ? Colors.grey[300]
                            : const Color(0xFF13694F),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isStreaming ? Icons.hourglass_empty : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else if (_isPlayingTTS)
                  GestureDetector(
                    onTap: _stopTTS,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  )
                else
                  _buildVoiceInputToggle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF13694F)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF13694F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}
