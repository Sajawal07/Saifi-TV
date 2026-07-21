import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}

class FavoriteVideo {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String type; // 'naat' or 'bayan'

  const FavoriteVideo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.type,
  });

  Map<String, String> toMap() => {
        'id': id,
        'title': title,
        'channelName': channelName,
        'thumbnailUrl': thumbnailUrl,
        'type': type,
      };

  factory FavoriteVideo.fromMap(Map<String, String> m) => FavoriteVideo(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        channelName: m['channelName'] ?? '',
        thumbnailUrl: m['thumbnailUrl'] ?? '',
        type: m['type'] ?? 'naat',
      );

  // Serialize as pipe-separated string for SharedPreferences
  String serialize() => [id, title, channelName, thumbnailUrl, type].join('|||');

  factory FavoriteVideo.deserialize(String s) {
    final parts = s.split('|||');
    return FavoriteVideo(
      id: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      channelName: parts.length > 2 ? parts[2] : '',
      thumbnailUrl: parts.length > 3 ? parts[3] : '',
      type: parts.length > 4 ? parts[4] : 'naat',
    );
  }
}

class FavoritesProvider extends ChangeNotifier {
  static const String _naatFavKey = 'fav_naats_v2';
  static const String _bayanFavKey = 'fav_bayanat_v2';
  static const String _surahFavKey = 'fav_surahs';

  List<FavoriteVideo> _favNaats = [];
  List<FavoriteVideo> _favBayanat = [];
  Set<int> _favSurahs = {};

  List<FavoriteVideo> get favNaats => _favNaats;
  List<FavoriteVideo> get favBayanat => _favBayanat;
  Set<int> get favSurahs => _favSurahs;

  FavoritesProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _favNaats = (prefs.getStringList(_naatFavKey) ?? [])
        .map((s) => FavoriteVideo.deserialize(s))
        .toList();
    _favBayanat = (prefs.getStringList(_bayanFavKey) ?? [])
        .map((s) => FavoriteVideo.deserialize(s))
        .toList();
    _favSurahs = (prefs.getStringList(_surahFavKey) ?? [])
        .map((e) => int.parse(e))
        .toSet();
    notifyListeners();
  }

  void toggleNaat(FavoriteVideo video) async {
    if (_favNaats.any((v) => v.id == video.id)) {
      _favNaats.removeWhere((v) => v.id == video.id);
    } else {
      _favNaats.add(video);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _naatFavKey, _favNaats.map((v) => v.serialize()).toList());
    notifyListeners();
  }

  void toggleBayan(FavoriteVideo video) async {
    if (_favBayanat.any((v) => v.id == video.id)) {
      _favBayanat.removeWhere((v) => v.id == video.id);
    } else {
      _favBayanat.add(video);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _bayanFavKey, _favBayanat.map((v) => v.serialize()).toList());
    notifyListeners();
  }

  void toggleSurah(int number) async {
    if (_favSurahs.contains(number)) {
      _favSurahs.remove(number);
    } else {
      _favSurahs.add(number);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _surahFavKey, _favSurahs.map((e) => e.toString()).toList());
    notifyListeners();
  }

  bool isNaatFav(String id) => _favNaats.any((v) => v.id == id);
  bool isBayanFav(String id) => _favBayanat.any((v) => v.id == id);
  bool isSurahFav(int number) => _favSurahs.contains(number);
}

class ZikrProvider extends ChangeNotifier {
  Map<String, int> _counts = {
    'qalb': 0,
    'ruh': 0,
    'sirri': 0,
    'khaffi': 0,
    'akhfa': 0,
    'nufs': 0,
    'sultan': 0,
    'nafi_asbat': 0,
  };

  Map<String, int> _cycles = {
    'qalb': 0,
    'ruh': 0,
    'sirri': 0,
    'khaffi': 0,
    'akhfa': 0,
    'nufs': 0,
    'sultan': 0,
    'nafi_asbat': 0,
  };

  Map<String, int> _targets = {
    'qalb': 100,
    'ruh': 100,
    'sirri': 100,
    'khaffi': 100,
    'akhfa': 100,
    'nufs': 100,
    'sultan': 100,
    'nafi_asbat': 100,
  };

  Map<String, int> get counts => _counts;
  Map<String, int> get cycles => _cycles;
  Map<String, int> get targets => _targets;

  ZikrProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _counts.keys) {
      _counts[key] = prefs.getInt('zikr_$key') ?? 0;
      _cycles[key] = prefs.getInt('cycles_$key') ?? 0;
      _targets[key] = prefs.getInt('target_$key') ?? 100;
    }
    notifyListeners();
  }

  void increment(String latifa) async {
    _counts[latifa] = (_counts[latifa] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikr_$latifa', _counts[latifa]!);
    notifyListeners();
  }

  void reset(String latifa) async {
    _counts[latifa] = 0;
    _cycles[latifa] = 0; // optional: also reset cycles? Actually let's just reset count. If they want to reset completely, we reset cycles too.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikr_$latifa', 0);
    await prefs.setInt('cycles_$latifa', 0);
    notifyListeners();
  }

  void completeCycle(String latifa) async {
    _counts[latifa] = 0;
    _cycles[latifa] = (_cycles[latifa] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikr_$latifa', 0);
    await prefs.setInt('cycles_$latifa', _cycles[latifa]!);
    notifyListeners();
  }

  void setTarget(String latifa, int target) async {
    _targets[latifa] = target;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_$latifa', target);
    notifyListeners();
  }

  int getCount(String latifa) => _counts[latifa] ?? 0;
  int getCycles(String latifa) => _cycles[latifa] ?? 0;
  int getTarget(String latifa) => _targets[latifa] ?? 100;
  bool isCompleted(String latifa) => getCount(latifa) >= getTarget(latifa);
}

class KhatamProvider extends ChangeNotifier {
  Map<int, int> _surahCounts = {};
  int _fullQuranCount = 0;

  Map<int, int> get surahCounts => _surahCounts;
  int get fullQuranCount => _fullQuranCount;

  KhatamProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _fullQuranCount = prefs.getInt('khatam_full') ?? 0;
    for (int i = 1; i <= 114; i++) {
      _surahCounts[i] = prefs.getInt('khatam_surah_$i') ?? 0;
    }
    notifyListeners();
  }

  void incrementSurah(int surahNumber) async {
    _surahCounts[surahNumber] = (_surahCounts[surahNumber] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('khatam_surah_$surahNumber', _surahCounts[surahNumber]!);
    notifyListeners();
  }

  void incrementFullQuran() async {
    _fullQuranCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('khatam_full', _fullQuranCount);
    notifyListeners();
  }

  void resetFullQuran() async {
    _fullQuranCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('khatam_full', 0);
    notifyListeners();
  }

  void resetSurah(int surahNumber) async {
    _surahCounts[surahNumber] = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('khatam_surah_$surahNumber', 0);
    notifyListeners();
  }

  int getSurahCount(int number) => _surahCounts[number] ?? 0;
}

class QuranSettingsProvider extends ChangeNotifier {
  static const String _showTranslationKey = 'quran_show_translation';
  static const String _fontSizeKey = 'quran_font_size';

  bool _showTranslation = true;
  double _fontSizeMultiplier = 1.0;

  bool get showTranslation => _showTranslation;
  double get fontSizeMultiplier => _fontSizeMultiplier;

  QuranSettingsProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _showTranslation = prefs.getBool(_showTranslationKey) ?? true;
    _fontSizeMultiplier = prefs.getDouble(_fontSizeKey) ?? 1.0;
    notifyListeners();
  }

  void toggleTranslation() async {
    _showTranslation = !_showTranslation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTranslationKey, _showTranslation);
    notifyListeners();
  }

  void increaseFontSize() async {
    if (_fontSizeMultiplier < 2.0) {
      _fontSizeMultiplier += 0.1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, _fontSizeMultiplier);
      notifyListeners();
    }
  }

  void decreaseFontSize() async {
    if (_fontSizeMultiplier > 0.6) {
      _fontSizeMultiplier -= 0.1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, _fontSizeMultiplier);
      notifyListeners();
    }
  }
}
