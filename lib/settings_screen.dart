import 'package:flutter/material.dart';

import 'settings_service.dart';

/// Settings screen for configuring the agent server URL.
///
/// Shown on first launch (when no config exists) or via the gear icon.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onSaved});

  /// Called after the user taps Save with valid settings.
  final VoidCallback onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _serverUrlController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text: SettingsService.agentServerUrl,
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      setState(() => _error = 'Agent server URL is required.');
      return;
    }

    SettingsService.agentServerUrl = serverUrl;
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure your agent server connection.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Agent Server URL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _serverUrlController,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
            cursorColor: Colors.white.withValues(alpha: 0.5),
            decoration: InputDecoration(
              hintText: SettingsService.defaultAgentServerUrl,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The address of the Python agent server.\n'
            'Stream API key and credentials are fetched\n'
            'automatically from the server.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.redAccent.withValues(alpha: 0.8),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save & Connect'),
            ),
          ),
        ],
      ),
    );
  }
}
