import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stream_chat/stream_chat.dart' as chat;
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'overlay_screen.dart';

enum _ErrorKind { serverUnreachable, other }

/// Root widget that initialises Stream Video + Chat and shows the overlay.
class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  // ---------------------------------------------------------------------------
  // Configuration — the token is fetched from the Python agent server so that
  // the Flutter app automatically uses the same Stream application.
  // ---------------------------------------------------------------------------
  static const _userId = 'sales-assistant-user';
  static const _agentServerUrl = 'http://localhost:8000';

  late final StreamVideo _videoClient;
  late final chat.StreamChatClient _chatClient;
  bool _initialized = false;
  _ErrorKind? _errorKind;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<({String token, String apiKey})> _fetchToken() async {
    final uri = Uri.parse('$_agentServerUrl/auth/token?user_id=$_userId');

    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Server returned ${response.statusCode}: ${response.body}',
        uri: uri,
      );
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    return (token: body['token'] as String, apiKey: body['apiKey'] as String);
  }

  Future<void> _init() async {
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
      await _videoClient.connect();

      // --- Stream Chat client (for receiving agent messages) ---
      _chatClient = chat.StreamChatClient(apiKey, logLevel: chat.Level.WARNING);
      await _chatClient.connectUser(
        chat.User(id: _userId),
        token,
      );

      setState(() => _initialized = true);
    } catch (e) {
      final isUnreachable = e is SocketException ||
          e is TimeoutException ||
          (e is http.ClientException &&
              e.message.contains('Connection refused'));

      setState(() {
        _errorKind =
            isUnreachable ? _ErrorKind.serverUnreachable : _ErrorKind.other;
        _errorDetail = e.toString();
      });
    }
  }

  void _retry() {
    setState(() {
      _errorKind = null;
      _errorDetail = null;
    });
    _init();
  }

  @override
  void dispose() {
    if (_initialized) {
      _chatClient.disconnectUser();
      _chatClient.dispose();
      _videoClient.disconnect();
      StreamVideo.reset();
    }
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
            // Dark tint over the frosted glass so white text stays readable
            // regardless of what's behind the window.
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
    if (_errorKind != null) {
      if (_errorKind == _ErrorKind.serverUnreachable) {
        return _StatusCard(
          icon: Icons.cloud_off_rounded,
          message:
              'It looks like your server isn\'t running yet.\n'
              'Please start your server and hit Reconnect.',
          actionLabel: 'Reconnect',
          onAction: _retry,
        );
      }
      return _StatusCard(
        icon: Icons.error_outline,
        message: 'Failed to connect:\n$_errorDetail',
        actionLabel: 'Retry',
        onAction: _retry,
      );
    }

    if (!_initialized) {
      return const _StatusCard(
        icon: Icons.hourglass_empty,
        message: 'Connecting to Stream…',
      );
    }

    return OverlayScreen(
      videoClient: _videoClient,
      chatClient: _chatClient,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
