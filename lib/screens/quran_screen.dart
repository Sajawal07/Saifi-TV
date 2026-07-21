import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/providers/app_providers.dart';
import '../models/app_models.dart';
import '../services/api_services.dart';
import '../widgets/common_widgets.dart';

// ── Quran Home Screen ─────────────────────────────────────────────────────────
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Surah> _surahs = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedReciter = 'ar.alafasy';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSurahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final surahs = await QuranService.fetchAllSurahs();
    if (mounted) {
      setState(() {
        _surahs = surahs;
        _loading = false;
      });
    }
  }

  List<Surah> get _filteredSurahs {
    if (_searchQuery.isEmpty) return _surahs;
    return _surahs.where((s) =>
        s.englishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.name.contains(_searchQuery) ||
        s.number.toString() == _searchQuery).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quran'),
        backgroundColor: AppColors.backgroundDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Surahs'),
            Tab(text: 'Khatam Counter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Surahs Tab ────────────────────────────────────────────────
          Column(
            children: [
              // Hero Image
              Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/quran.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Search Surah...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: _loading
                    ? const Center(child: TasbehLoader())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (ctx, i) {
                          final s = _filteredSurahs[i];
                          return _buildSurahTile(ctx, s);
                        },
                      ),
              ),
            ],
          ),
          // ── Khatam Counter Tab ────────────────────────────────────────
          _KhatamCounterTab(surahs: _surahs),
        ],
      ),
    );
  }

  Widget _buildSurahTile(BuildContext ctx, Surah s) {
    return Consumer<FavoritesProvider>(
      builder: (_, favs, __) => GestureDetector(
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => SurahDetailScreen(
              surah: s,
              selectedReciter: _selectedReciter,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${s.number}',
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(s.englishName, style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                ),
                Text(
                  s.name,
                  style: AppTextStyles.arabic.copyWith(fontSize: 20),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: s.revelationType == 'Meccan'
                        ? const Color(0xFF0277BD).withOpacity(0.3)
                        : const Color(0xFF2E7D32).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.revelationType,
                    style: AppTextStyles.label.copyWith(
                      color: s.revelationType == 'Meccan'
                          ? const Color(0xFF82B1FF)
                          : const Color(0xFF69F0AE),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.numberOfAyahs} Ayahs',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => favs.toggleSurah(s.number),
                  child: Icon(
                    favs.isSurahFav(s.number)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: favs.isSurahFav(s.number)
                        ? AppColors.gold
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Khatam Counter Tab ────────────────────────────────────────────────────────
class _KhatamCounterTab extends StatelessWidget {
  final List<Surah> surahs;
  const _KhatamCounterTab({required this.surahs});

  @override
  Widget build(BuildContext context) {
    return Consumer<KhatamProvider>(
      builder: (_, khatam, __) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Quran counter
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: AppColors.gold, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Full Quran Khatam', style: AppTextStyles.headingSmall),
                        Text(
                          '${khatam.fullQuranCount} times completed',
                          style: AppTextStyles.goldText.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.card,
                              title: const Text('Reset Counter', style: AppTextStyles.headingSmall),
                              content: const Text('Are you sure you want to reset the Full Quran Khatam counter?', style: AppTextStyles.bodyMedium),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: AppTextStyles.bodySmall),
                                ),
                                TextButton(
                                  onPressed: () {
                                    khatam.resetFullQuran();
                                    Navigator.pop(ctx);
                                  },
                                  child: Text('Reset', style: AppTextStyles.goldText),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          khatam.incrementFullQuran();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Masha\'Allah! Full Quran Khatam recorded!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.add, color: AppColors.buttonText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: 'Surah Khatam Counter'),
            const SizedBox(height: 12),
            ...surahs.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${s.number}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.buttonText, fontWeight: FontWeight.bold)),
                  ),
                ),
                title: Text(s.englishName, style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
                subtitle: Text(
                  '${khatam.getSurahCount(s.number)}x',
                  style: AppTextStyles.goldSmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (khatam.getSurahCount(s.number) > 0) ...[
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.card,
                              title: const Text('Reset Counter', style: AppTextStyles.headingSmall),
                              content: Text('Are you sure you want to reset the counter for ${s.englishName}?', style: AppTextStyles.bodyMedium),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: AppTextStyles.bodySmall),
                                ),
                                TextButton(
                                  onPressed: () {
                                    khatam.resetSurah(s.number);
                                    Navigator.pop(ctx);
                                  },
                                  child: Text('Reset', style: AppTextStyles.goldText),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => khatam.incrementSurah(s.number),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gold),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('+1 Read',
                            style: AppTextStyles.goldSmall.copyWith(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Surah Detail Screen ───────────────────────────────────────────────────────
class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  final String selectedReciter;
  const SurahDetailScreen({
    super.key,
    required this.surah,
    required this.selectedReciter,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  List<Map<String, dynamic>> _ayahs = [];
  bool _loading = true;
  String? _translatorName;

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;
  final List<GlobalKey> _ayahKeys = [];

  @override
  void initState() {
    super.initState();
    _load();

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() {
          _currentlyPlayingIndex = index;
        });
        _scrollToIndex(index);
      }
    });
  }

  void _scrollToIndex(int index) {
    if (index >= 0 && index < _ayahKeys.length) {
      final key = _ayahKeys[index];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await QuranService.fetchSurahWithTranslation(
      surahNumber: widget.surah.number,
      translationId: 'ur.jalandhry',
    );
    if (mounted) {
      final arabicAyahs = (data['arabic']?['ayahs'] as List? ?? []);
      final translationAyahs = (data['translation']?['ayahs'] as List? ?? []);
      final translatorName = data['translation']?['edition']?['name'] as String?;

      final audioSources = <AudioSource>[];

      setState(() {
        _translatorName = translatorName;
        _ayahs = List.generate(arabicAyahs.length, (i) {
          final arabic = arabicAyahs[i];
          final audioUrl = arabic['audio'] as String?;
          if (audioUrl != null) {
            audioSources.add(AudioSource.uri(Uri.parse(audioUrl)));
          }
          _ayahKeys.add(GlobalKey());
          return {
            'arabic': arabic,
            'translation': i < translationAyahs.length ? translationAyahs[i] : null,
          };
        });
        _loading = false;
      });

      if (audioSources.isNotEmpty) {
        try {
          await _audioPlayer.setAudioSource(
            ConcatenatingAudioSource(children: audioSources),
          );
        } catch (e) {
          debugPrint('Error setting audio source: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<QuranSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.surah.number}. ${widget.surah.englishName}',
        ),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: settings.decreaseFontSize,
            tooltip: 'Decrease Font Size',
          ),
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: settings.increaseFontSize,
            tooltip: 'Increase Font Size',
          ),
          IconButton(
            icon: Icon(
              settings.showTranslation ? Icons.translate : Icons.translate_outlined,
              color: settings.showTranslation ? AppColors.gold : AppColors.textMuted,
            ),
            onPressed: settings.toggleTranslation,
            tooltip: 'Toggle Translation',
          ),
          Consumer<KhatamProvider>(
            builder: (_, k, __) => IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.gold),
              onPressed: () {
                k.incrementSurah(widget.surah.number);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${widget.surah.englishName} khatam #${k.getSurahCount(widget.surah.number)} recorded!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              tooltip: 'Mark as Read',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: TasbehLoader())
          : CustomScrollView(
              slivers: [
                // Surah header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(gradient: AppColors.darkGradient),
                    child: Column(
                      children: [
                        Text(widget.surah.name,
                            style: AppTextStyles.arabicLarge,
                            textDirection: TextDirection.rtl),
                        const SizedBox(height: 8),
                        Text(widget.surah.englishNameTranslation,
                            style: AppTextStyles.goldText),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                          style: AppTextStyles.arabic.copyWith(fontSize: 22),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final ayah = _ayahs[i];
                      final arabic = ayah['arabic'] ?? {};
                      final trans = ayah['translation'] ?? {};
                      final isPlaying = _currentlyPlayingIndex == i;

                      return GestureDetector(
                        key: _ayahKeys[i],
                        onTap: () {
                          _audioPlayer.seek(Duration.zero, index: i);
                          _audioPlayer.play();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isPlaying
                                ? LinearGradient(colors: [AppColors.gold.withOpacity(0.15), AppColors.gold.withOpacity(0.05)])
                                : AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isPlaying ? AppColors.gold : AppColors.border.withOpacity(0.3),
                                width: isPlaying ? 2 : 1,
                            ),
                            boxShadow: isPlaying ? [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 12)] : null,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                arabic['text'] ?? '',
                                style: AppTextStyles.arabic.copyWith(
                                  fontSize: 28 * settings.fontSizeMultiplier,
                                  height: 1.8,
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.goldGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${arabic['numberInSurah'] ?? i + 1}',
                                      style: AppTextStyles.label.copyWith(color: AppColors.buttonText),
                                    ),
                                  ),
                                ],
                              ),
                              if (settings.showTranslation && trans.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const GoldDivider(),
                                const SizedBox(height: 8),
                                Text(
                                  trans['text'] ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 14 * settings.fontSizeMultiplier,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Translation by: $_translatorName',
                                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _ayahs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
      bottomNavigationBar: _ayahs.isEmpty ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                color: AppColors.textMuted,
                iconSize: 32,
                onPressed: () => _audioPlayer.seekToPrevious(),
              ),
              const SizedBox(width: 16),
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  
                  if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      width: 48,
                      height: 48,
                      child: const CircularProgressIndicator(color: AppColors.gold),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      iconSize: 64,
                      color: AppColors.gold,
                      onPressed: _audioPlayer.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      iconSize: 64,
                      color: AppColors.gold,
                      onPressed: _audioPlayer.pause,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.replay_circle_filled_rounded),
                      iconSize: 64,
                      color: AppColors.gold,
                      onPressed: () => _audioPlayer.seek(Duration.zero, index: 0),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                color: AppColors.textMuted,
                iconSize: 32,
                onPressed: () => _audioPlayer.seekToNext(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
