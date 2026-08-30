import 'package:universal_html/html.dart' as html;

/// Replaces the current address-bar entry without triggering navigation.
void webUrlReplace(String url) {
  html.window.history.replaceState(null, '', url);
}
