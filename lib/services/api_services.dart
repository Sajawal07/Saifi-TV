import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/api_constants.dart';
import '../models/app_models.dart';

// YouTube Service - fetches videos from approved channels
class YouTubeService {
  /// Fetches ALL videos from a channel using pagination (nextPageToken).
  /// [maxResults] = per-page count (max 50 allowed by YouTube API).
  /// [hardLimit] = absolute max videos to fetch (safety cap, 0 = no limit).
  static Future<List<VideoItem>> fetchChannelVideos({
    required String channelId,
    int maxResults = 50,
    int hardLimit = 50,
  }) async {
    final List<VideoItem> allVideos = [];
    String? nextPageToken;
    bool fetchedAtLeastOnePage = false;

    try {
      do {
        final uri = Uri.parse(
          '${ApiConstants.youtubeApiBase}/search'
          '?key=${ApiConstants.youtubeApiKey}'
          '&channelId=$channelId'
          '&part=snippet'
          '&type=video'
          '&order=date'
          '&maxResults=$maxResults'
          '${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}',
        );

        final response = await http.get(uri);
        if (response.statusCode != 200) break;

        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        allVideos.addAll(items.map((e) => VideoItem.fromJson(e)));

        nextPageToken = data['nextPageToken'] as String?;
        fetchedAtLeastOnePage = true;

        // Safety: stop if we hit the hard limit
        if (hardLimit > 0 && allVideos.length >= hardLimit) break;

      } while (nextPageToken != null);

      if (allVideos.isNotEmpty) return allVideos;
    } catch (e) {
      // If we got some pages before the error, return what we have
      if (fetchedAtLeastOnePage && allVideos.isNotEmpty) return allVideos;
    }

    return allVideos;
  }

  static List<VideoItem> _mockVideos(String channelId) {
    final List<Map<String, String>> videos = [
      {
        'id': 'hjj-Lq7Z9OY',
        'title': 'New Saifi Zikr Naat 2026 - Aj Sik Mitran Di Wadheri - Mufti Talha Badr Saifi',
        'channelName': 'Mufti Talha Badr Saifi',
      },
      {
        'id': 'TtufY4NutvU',
        'title': 'New SAIFI ZIKR Naat 2024/AYTHAY ALIF PAKAYA JANDA AY/ADNAN SAIFI/دل ❤️❤️❤️کو چھو جانے والا کلام',
        'channelName': 'Adnan Saifi',
      },
      {
        'id': 'SUGRn5Huaps',
        'title': 'JE TU VIKYA ISHQ BAZAR VE NAI | SUPER HIT SAIFI NAAT 2024 | ZAIDAN SAIFI | عشق بازار | HD NAAT 2024',
        'channelName': 'Zaidan Saifi',
      },
      {
        'id': 'gqc7u1TnfN0',
        'title': 'New Saifi Naat with Zikr | Wara Fana Laka Zikrak | Noor Mohammad Saifi',
        'channelName': 'Noor Mohammad Saifi',
      },
      {
        'id': 'DGw23uRoIoA',
        'title': 'New 2020 Heart Touching Saifi Naat sharif saifi ziker Nabi Ka Zikar By Sufi Hammad Raza Saifi',
        'channelName': 'Sufi Hammad Raza Saifi',
      },
    ];

    return videos.asMap().entries.map((entry) {
      final i = entry.key;
      final video = entry.value;
      final videoId = video['id']!;
      return VideoItem(
        id: 'mock_${channelId}_$i',
        title: video['title']!,
        channelName: video['channelName'] ?? 'Saifi TV Official',
        thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        youtubeVideoId: videoId,
        category: 'Naat',
      );
    }).toList();
  }
}

// Quran Service
class QuranService {
  static Future<List<Surah>> fetchAllSurahs() async {
    try {
      final response =
          await http.get(Uri.parse('${ApiConstants.alquranBase}/surah'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => Surah.fromJson(e)).toList();
      }
    } catch (e) {}
    return _staticSurahs();
  }

  static Future<Map<String, dynamic>> fetchSurahWithTranslation({
    required int surahNumber,
    String reciterId = 'ar.alafasy',
    String translationId = 'en.pickthall',
  }) async {
    try {
      final arabicResp = await http.get(
        Uri.parse('${ApiConstants.alquranBase}/surah/$surahNumber/$reciterId'),
      );
      final translationResp = await http.get(
        Uri.parse('${ApiConstants.alquranBase}/surah/$surahNumber/$translationId'),
      );

      if (arabicResp.statusCode == 200 && translationResp.statusCode == 200) {
        final arabicData = jsonDecode(arabicResp.body)['data'];
        final translationData = jsonDecode(translationResp.body)['data'];
        return {
          'arabic': arabicData,
          'translation': translationData,
        };
      }
    } catch (e) {}
    return {};
  }

  static String getAudioUrl(String reciterId, int surahNumber) {
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    return '${ApiConstants.quranAudioBase}/64/$reciterId/$paddedSurah.mp3';
  }

  // Static surah list as fallback
  static List<Surah> _staticSurahs() {
    final data = [
      {'number': 1, 'name': 'الفاتحة', 'englishName': 'Al-Faatiha', 'englishNameTranslation': 'The Opening', 'revelationType': 'Meccan', 'numberOfAyahs': 7},
      {'number': 2, 'name': 'البقرة', 'englishName': 'Al-Baqara', 'englishNameTranslation': 'The Cow', 'revelationType': 'Medinan', 'numberOfAyahs': 286},
      {'number': 3, 'name': 'آل عمران', 'englishName': 'Aal-i-Imraan', 'englishNameTranslation': 'The Family of Imraan', 'revelationType': 'Medinan', 'numberOfAyahs': 200},
      {'number': 4, 'name': 'النساء', 'englishName': 'An-Nisaa', 'englishNameTranslation': 'The Women', 'revelationType': 'Medinan', 'numberOfAyahs': 176},
      {'number': 5, 'name': 'المائدة', 'englishName': 'Al-Maaida', 'englishNameTranslation': 'The Table', 'revelationType': 'Medinan', 'numberOfAyahs': 120},
      {'number': 6, 'name': 'الأنعام', 'englishName': 'Al-An\'am', 'englishNameTranslation': 'The Cattle', 'revelationType': 'Meccan', 'numberOfAyahs': 165},
      {'number': 7, 'name': 'الأعراف', 'englishName': 'Al-A\'raaf', 'englishNameTranslation': 'The Heights', 'revelationType': 'Meccan', 'numberOfAyahs': 206},
      {'number': 8, 'name': 'الأنفال', 'englishName': 'Al-Anfaal', 'englishNameTranslation': 'The Spoils of War', 'revelationType': 'Medinan', 'numberOfAyahs': 75},
      {'number': 9, 'name': 'التوبة', 'englishName': 'At-Tawba', 'englishNameTranslation': 'The Repentance', 'revelationType': 'Medinan', 'numberOfAyahs': 129},
      {'number': 10, 'name': 'يونس', 'englishName': 'Yunus', 'englishNameTranslation': 'Jonas', 'revelationType': 'Meccan', 'numberOfAyahs': 109},
      {'number': 36, 'name': 'يس', 'englishName': 'Yaseen', 'englishNameTranslation': 'Ya-Seen', 'revelationType': 'Meccan', 'numberOfAyahs': 83},
      {'number': 67, 'name': 'الملك', 'englishName': 'Al-Mulk', 'englishNameTranslation': 'The Sovereignty', 'revelationType': 'Meccan', 'numberOfAyahs': 30},
      {'number': 112, 'name': 'الإخلاص', 'englishName': 'Al-Ikhlaas', 'englishNameTranslation': 'Sincerity', 'revelationType': 'Meccan', 'numberOfAyahs': 4},
      {'number': 113, 'name': 'الفلق', 'englishName': 'Al-Falaq', 'englishNameTranslation': 'The Daybreak', 'revelationType': 'Meccan', 'numberOfAyahs': 5},
      {'number': 114, 'name': 'الناس', 'englishName': 'An-Naas', 'englishNameTranslation': 'Mankind', 'revelationType': 'Meccan', 'numberOfAyahs': 6},
    ];
    return data.map((e) => Surah.fromJson(e)).toList();
  }
}

class PrayerLocationData {
  final PrayerTimes? times;
  final String locationName;
  final bool locationError;
  PrayerLocationData({this.times, required this.locationName, required this.locationError});
}

// Prayer Times Service
class PrayerTimesService {
  static PrayerLocationData? _cachedData;
  static DateTime? _cacheTime;

  static Future<PrayerLocationData> fetchPrayerData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedData != null && _cacheTime != null) {
      final now = DateTime.now();
      // Use cache if within 12 hours and same day
      if (now.difference(_cacheTime!).inHours < 12 && now.day == _cacheTime!.day) {
        return _cachedData!;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    
    bool hasLocationError = false;
    double? lat;
    double? lng;
    String locationName = '';

    try {
      // 1. Check if location service itself is ON
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location service disabled');
      }

      // 2. Check / request permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final request = await Geolocator.requestPermission();
        if (request == LocationPermission.denied || request == LocationPermission.deniedForever) {
          throw Exception('Location denied');
        }
      } else if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permanently denied');
      }

      // 3. Try to get current position — give it 15 seconds
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // 4. Fallback: use last known position if getCurrentPosition times out
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) throw Exception('No position available');

      lat = pos.latitude;
      lng = pos.longitude;
      
      try {
        final placemarks = await placemarkFromCoordinates(lat!, lng!);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
          locationName = city.isNotEmpty ? '$city, ${place.country}' : place.country ?? '';
        }
      } catch (_) {}

      if (locationName.isEmpty) {
         locationName = '${lat!.toStringAsFixed(3)}°, ${lng!.toStringAsFixed(3)}°';
      }

      await prefs.setDouble('last_lat', lat!);
      await prefs.setDouble('last_lng', lng!);
      await prefs.setString('last_city', locationName);
      
    } catch (_) {
      hasLocationError = true;
      lat = prefs.getDouble('last_lat');
      lng = prefs.getDouble('last_lng');
      locationName = prefs.getString('last_city') ?? 'Karachi, Pakistan';
    }

    PrayerTimes? times;
    if (lat != null && lng != null) {
      times = await fetchByCoords(lat: lat, lng: lng);
    } else {
      times = await fetchByCity(city: 'Karachi', country: 'Pakistan');
      lat = 24.8607;
      lng = 67.0011;
      await prefs.setDouble('last_lat', lat);
      await prefs.setDouble('last_lng', lng);
      await prefs.setString('last_city', 'Karachi, Pakistan');
    }

    final result = PrayerLocationData(
      times: times,
      locationName: locationName,
      locationError: hasLocationError,
    );

    _cachedData = result;
    _cacheTime = DateTime.now();
    return result;
  }

  static Future<PrayerTimes?> fetchByCity({
    required String city,
    required String country,
    int method = 1,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.day}-${now.month}-${now.year}';
      final uri = Uri.parse(
        '${ApiConstants.aladhanBase}/timingsByCity/$dateStr'
        '?city=$city&country=$country&method=$method',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PrayerTimes.fromJson(data['data']);
      }
    } catch (e) {}
    return null;
  }

  static Future<PrayerTimes?> fetchByCoords({
    required double lat,
    required double lng,
    int method = 1,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.day}-${now.month}-${now.year}';
      final uri = Uri.parse(
        '${ApiConstants.aladhanBase}/timings/$dateStr'
        '?latitude=$lat&longitude=$lng&method=$method',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PrayerTimes.fromJson(data['data']);
      }
    } catch (e) {}
    return null;
  }
}

// Hadith Service
class HadithService {
  static Future<HadithItem?> fetchDailyHadith() async {
    return _getDailyHadith();
  }

  static HadithItem _getDailyHadith() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final hadiths = _hadiths();
    return hadiths[dayOfYear % hadiths.length];
  }

  static List<HadithItem> _hadiths() => [
    const HadithItem(
      id: 1,
      bookReference: 'Sahih Al-Bukhari: 1',
      arabicText: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى.',
      text: 'اعمال کا دارومدار نیتوں پر ہے، اور ہر شخص کو وہی ملے گا جس کی اس نے نیت کی۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 1,
      narrator: 'Hazrat Umar ibn al-Khattab (R.A)',
    ),
    const HadithItem(
      id: 6018,
      bookReference: 'Sahih Al-Bukhari: 6018',
      arabicText: 'أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا.',
      text: 'مومنوں میں سب سے کامل ایمان والا وہ ہے جس کے اخلاق سب سے اچھے ہوں۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 78,
      narrator: 'Hazrat Abu Hurairah (R.A)',
    ),
    const HadithItem(
      id: 2318,
      bookReference: 'Sahih Muslim: 2318',
      arabicText: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ.',
      text: 'اپنے بھائی کے چہرے پر تمہارا مسکرانا بھی صدقہ ہے۔',
      bookName: 'Sahih Muslim',
      bookSlug: 'muslim',
      chapterId: 12,
      narrator: 'Hazrat Abu Zarr (R.A)',
    ),
    const HadithItem(
      id: 5027,
      bookReference: 'Sahih Al-Bukhari: 5027',
      arabicText: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ.',
      text: 'تم میں سب سے بہتر وہ شخص ہے جو قرآن سیکھے اور دوسروں کو سکھائے۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 61,
      narrator: 'Hazrat Usman ibn Affan (R.A)',
    ),
    const HadithItem(
      id: 2564,
      bookReference: 'Sahih Al-Bukhari: 2564',
      arabicText: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ.',
      text: 'مسلمان وہ ہے جس کی زبان اور ہاتھ سے دوسرے مسلمان محفوظ رہیں۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 2,
      narrator: 'Hazrat Abdullah ibn Amr (R.A)',
    ),
    const HadithItem(
      id: 6474,
      bookReference: 'Sahih Al-Bukhari: 6474',
      arabicText: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ.',
      text: 'جو شخص اللہ اور آخرت کے دن پر ایمان رکھتا ہو، وہ یا اچھی بات کہے یا خاموش رہے۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 78,
      narrator: 'Hazrat Abu Hurairah (R.A)',
    ),
    const HadithItem(
      id: 13,
      bookReference: 'Sahih Al-Bukhari: 13',
      arabicText: 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.',
      text: 'تم میں سے کوئی اس وقت تک مومن نہیں ہو سکتا جب تک کہ اپنے بھائی کے لیے وہی نہ پسند کرے جو اپنے لیے پسند کرتا ہے۔',
      bookName: 'Sahih Al-Bukhari',
      bookSlug: 'bukhari',
      chapterId: 2,
      narrator: 'Hazrat Anas ibn Malik (R.A)',
    ),
  ];
}


