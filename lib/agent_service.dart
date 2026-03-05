import 'dart:convert';

import 'package:http/http.dart' as http;

/// Simple HTTP client to communicate with the Vision Agents server.
class AgentService {
  AgentService({this.baseUrl = 'http://localhost:8000'});

  final String baseUrl;
  String? _sessionId;

  String? get sessionId => _sessionId;

  /// Set the meeting context for the next session.
  Future<void> setContext(String context) async {
    await http.put(
      Uri.parse('$baseUrl/context'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'context': context}),
    );
  }

  String? _callId;

  /// Start a new agent session for the given call.
  Future<String> startSession({
    required String callId,
    String callType = 'default',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calls/$callId/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'call_type': callType}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to start agent session: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _sessionId = data['session_id'] as String?;
    _callId = callId;
    return _sessionId ?? '';
  }

  /// Stop the current agent session.
  Future<void> stopSession() async {
    final sid = _sessionId;
    final cid = _callId;
    if (sid == null || cid == null) return;

    try {
      await http.delete(Uri.parse('$baseUrl/calls/$cid/sessions/$sid'));
    } catch (_) {
      // Best effort — the server may already be down.
    }
    _sessionId = null;
    _callId = null;
  }
}
