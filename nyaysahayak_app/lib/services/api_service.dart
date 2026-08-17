import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API client for the NyaySahayak FastAPI backend.
class ApiService {
  // ───────────────────────────────────────────────
  // Change this to your machine's LAN IP or ngrok URL
  // when running on a physical device.
  // ───────────────────────────────────────────────
  static String get baseUrl => dotenv.get('BASE_URL');
  // ─── Auth ─────────────────────────────────────

  /// Registers/logs-in a user record on the backend (post Firebase Auth).
  static Future<Map<String, dynamic>> authLogin({
    required String uid,
    required String email,
    String role = 'victim',
  }) async {
    final res = await http.post(
      Uri.parse('${baseUrl}api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'email': email, 'role': role}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Firebase Auth REST ────────────────────────
  // Removed custom implementation, using native firebase_auth SDK instead.

  // ─── Cases ────────────────────────────────────

  /// Fetches all cases for a user.
  static Future<List<dynamic>> getCases(String uid) async {
    final res = await http.get(Uri.parse('${baseUrl}api/cases?uid=$uid'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['cases'] as List?) ?? [];
  }

  /// Saves a new case.
  static Future<bool> saveCase({
    required String uid,
    required String caseId,
    required Map<String, dynamic> structuredReport,
    required List<Map<String, dynamic>> sessionData,
  }) async {
    final res = await http.post(
      Uri.parse('${baseUrl}api/cases'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'case_id': caseId,
        'structured_report': structuredReport,
        'session_data': sessionData,
      }),
    );
    return res.statusCode == 200;
  }

  // ─── Chat History ─────────────────────────────

  /// Fetches nearby scams
  static Future<List<dynamic>> getNearbyScams(double lat, double lon) async {
    try {
      final res = await http.get(
        Uri.parse('${baseUrl}api/scams/nearby?lat=$lat&lon=$lon'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['scams'] as List?) ?? [];
      }
    } catch (e) {
      print('Error fetching scams: $e');
    }
    return [];
  }

  /// Fetches all chat sessions for a user.
  static Future<List<dynamic>> getChatSessions(String uid) async {
    final res = await http.get(
      Uri.parse('${baseUrl}api/chat/sessions?uid=$uid'),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['sessions'] as List?) ?? [];
  }

  /// Fetches messages in a specific chat session.
  static Future<List<dynamic>> getChatHistory(
    String uid,
    String sessionId,
  ) async {
    final res = await http.get(
      Uri.parse('${baseUrl}api/chat/history?uid=$uid&session_id=$sessionId'),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['history'] as List?) ?? [];
  }

  /// Syncs chat history for a session to the backend.
  static Future<bool> syncChatHistory({
    required String uid,
    required String sessionId,
    required List<Map<String, dynamic>> sessionData,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${baseUrl}api/chat/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'session_id': sessionId,
          'session_data': sessionData,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Lawyers ──────────────────────────────────

  /// Fetches all lawyers.
  static Future<List<dynamic>> getLawyers() async {
    final res = await http.get(Uri.parse('${baseUrl}api/lawyers'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['lawyers'] as List?) ?? [];
  }

  /// Semantic search for lawyers.
  static Future<List<dynamic>> searchLawyers({
    required String query,
    int topK = 5,
  }) async {
    final res = await http.post(
      Uri.parse('${baseUrl}api/lawyers/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query, 'top_k': topK}),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['lawyers'] as List?) ?? [];
  }

  // ─── Streaming Chat ───────────────────────────

  /// Opens an ndjson stream to `/chat/stream` and yields parsed event maps.
  ///
  /// Each yielded map has at least a `type` field:
  ///   - `answer`  → `content` (String)
  ///   - `data`    → `structured_report`, `suggested_actions`, `case_id`
  ///   - `agent_start` → `agent`
  ///   - `error`   → `content`
  static Stream<Map<String, dynamic>> streamChat({
    required String query,
    required String userId,
    String? userName,
    String? sessionId,
    List<Map<String, dynamic>>? sessionHistory,
    Map<String, double>? location,
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/stream'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'query': query,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (sessionId != null) 'session_id': sessionId,
      if (sessionHistory != null) 'session_history': sessionHistory,
      if (location != null) 'location': location,
    });

    try {
      final client = http.Client();
      final streamedResponse = await client.send(request);

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final event = jsonDecode(trimmed) as Map<String, dynamic>;
          yield event;
        } catch (_) {
          // skip malformed lines
        }
      }
      client.close();
    } on SocketException catch (e) {
      yield {
        'type': 'error',
        'content': 'Cannot connect to server: ${e.message}',
      };
    } catch (e) {
      yield {'type': 'error', 'content': e.toString()};
    }
  }

  // ─── Transcription ────────────────────────────

  /// Sends an audio file to the backend for speech-to-text.
  static Future<String?> transcribeAudio(String path) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/transcribe'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', path));
      request.fields['language_code'] = 'unknown';

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Matching the web interface response parsing logic
        return data['transcript'] ??
            data['text'] ??
            data['data'] ??
            data['message'];
      }
    } catch (e) {
      print('Error transcribing audio: $e');
    }
    return null;
  }

  /// Sends text to the backend for text-to-speech synthesis and returns MP3 bytes.
  static Future<Uint8List?> synthesizeAudio(
    String text, {
    String langCode = 'hi-IN',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/synthesize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'target_language_code': langCode}),
      );
      if (res.statusCode == 200) {
        return res.bodyBytes; // Raw MP3 bytes
      } else {
        print('Error from TTS: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Network Error generating TTS: $e');
    }
    return null;
  }
}
