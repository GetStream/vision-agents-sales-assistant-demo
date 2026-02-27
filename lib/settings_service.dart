import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app settings (agent server URL).
class SettingsService {
  SettingsService._();

  static const _keyAgentServerUrl = 'agent_server_url';

  static const defaultAgentServerUrl = 'http://localhost:8000';

  static late final SharedPreferences _prefs;

  /// Call once at app startup before reading any values.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Agent server URL ----

  static String get agentServerUrl =>
      _prefs.getString(_keyAgentServerUrl)?.trim() ?? defaultAgentServerUrl;

  static set agentServerUrl(String value) =>
      _prefs.setString(_keyAgentServerUrl, value.trim());

  /// Whether the minimum required settings are present.
  static bool get isConfigured => agentServerUrl.isNotEmpty;
}
