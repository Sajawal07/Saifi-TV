// API endpoint constants for all external services
class ApiConstants {
  // YouTube Data API v3
  static const String youtubeApiKey = 'AIzaSyBa49iwUgJo_7yMy4emZi9TVLlePj_m-lw';
  static const String youtubeApiBase = 'https://www.googleapis.com/youtube/v3';

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
  static const List<Map<String, String>> approvedNaatChannels = [
    {'channelId': 'UCv0j01aAHX9HkHPtRMxPlHg', 'name': 'Mufti Talha Badr Saifi'},
    // Add more authentic Naat channels here in the future
  ];

  static const List<Map<String, String>> approvedBayanatChannels = [
    {'channelId': 'UCv0j01aAHX9HkHPtRMxPlHg', 'name': 'Mufti Talha Badr Saifi'},
    // Add more authentic Bayanat channels here in the future
  ];



  // Firestore Collections
  static const String naatCollection = 'naats';
  static const String bayanatCollection = 'bayanat';
  static const String approvedChannelsCollection = 'approved_channels';
  static const String notificationsCollection = 'notifications';
}
