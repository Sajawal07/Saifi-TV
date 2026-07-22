// Video model for Naats and Bayanat
class VideoItem {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String youtubeVideoId;
  final String category;
  final DateTime? publishedAt;
  final String? description;

  const VideoItem({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.youtubeVideoId,
    required this.category,
    this.publishedAt,
    this.description,
  });

  /// True when this video belongs in the Bayanat section (not Naats).
  bool get isBayan => category == 'Bayan';

  /// Auto-categorize from title/description so mixed channels split correctly.
  static String categorizeFromText(String title, String description) {
    final s = '${title.toLowerCase()} ${description.toLowerCase()}';

    // Urs events
    if (RegExp(r'\burs\b').hasMatch(s) || s.contains('urs mubarak')) {
      return 'Urs';
    }

    // Mehfil (often includes naats / zikr)
    if (s.contains('mehfil')) return 'Mehfil';

    // Explicit naat-family keywords first
    if (s.contains('manqabat')) return 'Manqabat';
    if (s.contains('salaam') || RegExp(r'\bsalam\b').hasMatch(s)) {
      return 'Salaam';
    }
    if (RegExp(r'\bhamd\b').hasMatch(s)) return 'Hamd';
    if (s.contains('naat')) {
      if (s.contains('ramzan') || s.contains('ramadan')) return 'Ramzan Special';
      if (s.contains('milad') || s.contains('rabi ul awal')) return 'Milad';
      return 'Naat';
    }

    // Bayan / lecture indicators (SAIFI CHANNEL style titles)
    if (s.contains('bayan') ||
        s.contains('byan') ||
        s.contains('dars') ||
        s.contains('fazail') ||
        s.contains('islahi') ||
        s.contains('interview') ||
        s.contains('ahmiyat') ||
        s.contains('anjam') ||
        s.contains('huqooq') ||
        s.contains('molana') ||
        s.contains('maulana') ||
        s.contains('allama') ||
        (s.contains('mufti') && !s.contains('naat'))) {
      return 'Bayan';
    }

    // Religious talks without "naat" in the title
    if (s.contains('ramzan') ||
        s.contains('ramadan') ||
        s.contains('roza') ||
        s.contains('hajj') ||
        s.contains('namaz') ||
        s.contains('quran') ||
        s.contains('hadees') ||
        s.contains('hadeea') ||
        s.contains('shareeat') ||
        s.contains('shariyat') ||
        s.contains('tareeqat') ||
        s.contains('tassawuf')) {
      return 'Bayan';
    }

    return 'Naat';
  }

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final high = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};
    final resourceId = snippet['resourceId'] ?? {};
    final videoId = resourceId['videoId'] ?? (json['id'] is Map ? json['id']['videoId'] : json['id']);
    
    final title = snippet['title']?.toString() ?? '';
    final description = snippet['description']?.toString() ?? '';

    String category = categorizeFromText(title, description);
    if (json['category'] != null && category == 'Naat') {
      category = json['category'].toString();
    }

    return VideoItem(
      id: videoId?.toString() ?? '',
      title: title,
      channelName: snippet['channelTitle'] ?? '',
      thumbnailUrl: high['url'] ?? '',
      youtubeVideoId: videoId?.toString() ?? '',
      category: category,
      publishedAt: snippet['publishedAt'] != null
          ? DateTime.tryParse(snippet['publishedAt'])
          : null,
      description: description,
    );
  }

  factory VideoItem.fromFirestore(Map<String, dynamic> data, String docId) {
    return VideoItem(
      id: docId,
      title: data['title'] ?? '',
      channelName: data['channelName'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      category: data['category'] ?? 'General',
      description: data['description'],
    );
  }
}

// Surah model
class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['revelationType'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
    );
  }
}

// Ayah model
class Ayah {
  final int number;
  final String text;
  final String? translation;
  final int surahNumber;
  final int numberInSurah;
  final String? audio;

  const Ayah({
    required this.number,
    required this.text,
    required this.surahNumber,
    required this.numberInSurah,
    this.translation,
    this.audio,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      surahNumber: json['surah']?['number'] ?? 0,
      numberInSurah: json['numberInSurah'] ?? 0,
      translation: json['translation'],
      audio: json['audio'],
    );
  }
}

// Hadith model
class HadithItem {
  final int id;
  final String text;
  final String? arabicText;
  final String bookName;
  final String bookSlug;
  final int chapterId;
  final String? narrator;
  final String? bookReference; // e.g. 'Sahih Bukhari: 1'

  const HadithItem({
    required this.id,
    required this.text,
    this.arabicText,
    required this.bookName,
    required this.bookSlug,
    required this.chapterId,
    this.narrator,
    this.bookReference,
  });

  factory HadithItem.fromJson(Map<String, dynamic> json) {
    return HadithItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      arabicText: json['arabicText'],
      bookName: json['book_name'] ?? 'Sahih Bukhari',
      bookSlug: json['book'] ?? 'bukhari',
      chapterId: json['chapterId'] ?? 0,
      narrator: json['narrator'],
      bookReference: json['bookReference'],
    );
  }
}

// Prayer Times model
class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String sunrise;
  final String date;
  final String city;
  final String country;

  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sunrise,
    required this.date,
    this.city = '',
    this.country = '',
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] ?? {};
    final dateInfo = json['date'] ?? {};
    final meta = json['meta'] ?? {};
    return PrayerTimes(
      fajr: timings['Fajr'] ?? '--:--',
      dhuhr: timings['Dhuhr'] ?? '--:--',
      asr: timings['Asr'] ?? '--:--',
      maghrib: timings['Maghrib'] ?? '--:--',
      isha: timings['Isha'] ?? '--:--',
      sunrise: timings['Sunrise'] ?? '--:--',
      date: dateInfo['readable'] ?? '',
      city: meta['timezone']?.toString().split('/').last.replaceAll('_', ' ') ?? '',
      country: '',
    );
  }
}
