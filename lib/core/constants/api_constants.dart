// API endpoint constants for all external services
class ApiConstants {
  // YouTube Data API v3 — key comes from AppConfig (dart-define / gitignored secrets)
  static const String youtubeApiBase = 'https://www.googleapis.com/youtube/v3';

  // Android package & certificate fingerprints (for API key restriction headers)
  static const String androidPackageName = 'com.saifitv.app';
  // Debug keystore SHA-1 (without colons, uppercase)
  static const String debugCertSha1 = '2FA85BD3EE38FD9585E78BCB7BCB9D330AEC4602';
  // Release keystore SHA-1 (without colons, uppercase)
  static const String releaseCertSha1 = 'BB8A9CF1FC74740E2C0F5ECE216671EBA70F3204';

  // Quran APIs
  static const String alquranBase = 'https://api.alquran.cloud/v1';
  static const String quranTextBase = 'https://api.alquran.cloud/v1';
  static const String quranAudioBase = 'https://cdn.islamic.network/quran/audio';

  // Hadith API
  static const String hadithApiBase = 'https://api.hadith.gts.io';
  static const String hadithApiBukhari = 'https://api.hadith.gts.io/v1/hadiths/bukhari?range_start=1&range_end=1000';

  // Prayer Times API (Aladhan)
  static const String aladhanBase = 'https://api.aladhan.com/v1';
  static const String prayerTimingsEndpoint = '$aladhanBase/timingsByCity';
  static const String prayerTimingsByCoords = '$aladhanBase/timings';

  // Hijri Calendar
  static const String hijriBase = '$aladhanBase/gToH';

  // Quran Reciters (Identifiers for alquran.cloud)
  static const List<Map<String, String>> reciters = [
    {'id': 'ar.alafasy', 'name': 'Mishary Alafasy'},
    {'id': 'ar.abdulsamad', 'name': 'Abdul Samad'},
    {'id': 'ar.minshawi', 'name': 'Minshawi (Mujawwad)'},
    {'id': 'ar.husary', 'name': 'Mahmoud Khalil Al-Husary'},
    {'id': 'ar.sudais', 'name': 'Abdul Rahman Al-Sudais'},
  ];

  // Approved YouTube Channels (editable - will also be fetched from Firestore)
  // Both channels are fetched & merged; titles auto-split into Naat / Bayan sections.
  static const List<Map<String, String>> approvedNaatChannels = [
    {'channelId': 'UCJdK2Cuk2LLETQeMwUU2gPg', 'name': 'SAIFI CHANNEL'},
    {'channelId': 'UCv0j01aAHX9HkHPtRMxPlHg', 'name': 'Saifi Studio Official'},
  ];

  static const List<Map<String, String>> approvedBayanatChannels = [
    {'channelId': 'UCJdK2Cuk2LLETQeMwUU2gPg', 'name': 'SAIFI CHANNEL'},
    {'channelId': 'UCv0j01aAHX9HkHPtRMxPlHg', 'name': 'Saifi Studio Official'},
  ];



  // Firestore Collections
  static const String naatCollection = 'naats';
  static const String bayanatCollection = 'bayanat';
  static const String approvedChannelsCollection = 'approved_channels';
  static const String notificationsCollection = 'notifications';
}
