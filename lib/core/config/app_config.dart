import 'app_secrets.dart';

/// Legal / policy URLs used across the app (clickable disclosures).
class AppUrls {
  /// Hosted privacy policy (GitHub Pages).
  /// Enable: GitHub → Settings → Pages → Deploy from branch → /docs folder
  static const String privacyPolicy =
      'https://sajawal07.github.io/Saifi-TV/privacy-policy.html';

  static const String youtubeTerms = 'https://www.youtube.com/t/terms';
  static const String googlePrivacy = 'https://policies.google.com/privacy';
  static const String supportEmail = 'support@saifitv.app';
}

/// Build-time / local secrets.
/// Release: `flutter build appbundle --dart-define=YOUTUBE_API_KEY=...`
/// Debug fallback: gitignored [AppSecrets] in app_secrets.dart
class AppConfig {
  static String get youtubeApiKey {
    const fromDefine = String.fromEnvironment(
      'YOUTUBE_API_KEY',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return AppSecrets.youtubeApiKey;
  }
}
