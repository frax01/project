import 'package:url_launcher/url_launcher.dart';

final RegExp _knownSchemes = RegExp(r'^(mailto|tel|sms):', caseSensitive: false);

/// Cleans a link typed by a user: trims it and adds `https://` when the
/// scheme is missing (e.g. `www.example.com/doc`). Returns null if empty.
String? normalizeUrl(String? raw) {
  final String url = (raw ?? '').trim();
  if (url.isEmpty) return null;
  if (url.contains('://') || _knownSchemes.hasMatch(url)) return url;
  return 'https://$url';
}

/// Opens a link or an attachment. http(s) links open in the in-app browser
/// (SFSafariViewController on iOS, Custom Tabs on Android), with the external
/// browser as a fallback. Returns false if nothing could open it.
///
/// Replaces the `flutter_web_browser` plugin, which silently does nothing on
/// iOS now that the app uses the UIScene lifecycle.
Future<bool> openLink(String? rawUrl) async {
  final String? url = normalizeUrl(rawUrl);
  final Uri? uri = url == null ? null : Uri.tryParse(url);
  if (uri == null) return false;

  if (uri.scheme == 'http' || uri.scheme == 'https') {
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
    } catch (_) {
      // fall through to the external browser
    }
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
