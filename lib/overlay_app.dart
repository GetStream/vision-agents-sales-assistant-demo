import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stream_chat/stream_chat.dart' as chat;
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'overlay_screen.dart';
import 'settings_screen.dart';
import 'settings_service.dart';

/// Root widget that initialises Stream Video + Chat and shows the overlay.
class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  static const _userId = 'sales-assistant-user';

  StreamVideo? _videoClient;
  chat.StreamChatClient? _chatClient;

  bool _showSettings = false;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Connect on launch — settings always have a default server URL.
  Future<void> _boot() async {
    await _connect();
  }

  /// Fetch a user token (and API key) from the agent server.
  Future<({String token, String apiKey})> _fetchToken() async {
    final base = SettingsService.agentServerUrl;
    final uri = Uri.parse('$base/auth/token?user_id=$_userId');
    final response = await http.get(uri);
    final body = json.decode(response.body) as Map<String, dynamic>;
    return (token: body['token'] as String, apiKey: body['apiKey'] as String);
  }

  /// Connect to Stream Video + Chat using the current settings.
  Future<void> _connect() async {
    setState(() {
      _error = null;
      _initialized = false;
      _showSettings = false;
    });

    try {
      final (:token, :apiKey) = await _fetchToken();

      // --- Stream Video client ---
      final videoUser = User.regular(
        userId: _userId,
        name: 'Sales Assistant User',
        role: 'admin',
      );

      _videoClient = StreamVideo(
        apiKey,
        user: videoUser,
        userToken: token,
        tokenLoader: (_) async {
          final result = await _fetchToken();
          return result.token;
        },
        options: const StreamVideoOptions(logPriority: Priority.info),
      );
      await _videoClient!.connect();

      // --- Stream Chat client ---
      _chatClient = chat.StreamChatClient(apiKey, logLevel: chat.Level.WARNING);
      await _chatClient!.connectUser(chat.User(id: _userId), token);

      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Disconnect existing clients so we can reconnect with new settings.
  Future<void> _disconnect() async {
    if (_initialized) {
      _chatClient?.disconnectUser();
      _chatClient?.dispose();
      _chatClient = null;
      _videoClient?.disconnect();
      StreamVideo.reset();
      _videoClient = null;
      _initialized = false;
    }
  }

  /// Called when the user taps the gear icon to open settings.
  void _openSettings() {
    setState(() => _showSettings = true);
  }

  /// Called when the user saves settings.
  Future<void> _onSettingsSaved() async {
    await _disconnect();
    await _connect();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Colors.transparent,
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: const Color(0x50000000),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_showSettings) {
      return SettingsScreen(onSaved: _onSettingsSaved);
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onOpenSettings: _openSettings,
      );
    }

    if (!_initialized) {
      return const _StatusCard(
        icon: Icons.hourglass_empty,
        message: 'Connecting to Stream…',
      );
    }

    return OverlayScreen(
      videoClient: _videoClient!,
      chatClient: _chatClient!,
      agentServerUrl: SettingsService.agentServerUrl,
      onOpenSettings: _openSettings,
    );
  }
}

// -----------------------------------------------------------------------------
// Helper widgets
// -----------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onOpenSettings});

  final String message;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Failed to connect:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Open Settings'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
