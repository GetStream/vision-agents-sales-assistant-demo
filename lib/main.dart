import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';

import 'overlay_app.dart';
import 'settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManipulator.initialize(enableWindowDelegate: true);
  WindowManipulator.makeWindowFullyTransparent();
  await SettingsService.init();
  runApp(const OverlayApp());
}
