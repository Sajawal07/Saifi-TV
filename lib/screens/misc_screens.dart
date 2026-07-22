import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/providers/app_providers.dart';
import '../models/app_models.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/disclaimer_dialog.dart';
import 'naats_bayanat_screen.dart';
import 'quran_screen.dart';


// ── Favorites Screen ─────────────────────────────────────────────────────────
class FavoritesScreen extends StatefulWidget {
  final Function(int) onNavTap;
  const FavoritesScreen({super.key, required this.onNavTap});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: AppColors.backgroundDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_rounded, size: 18), text: 'Videos'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Quran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VideosTab(onNavTap: widget.onNavTap),
          _QuranTab(),
        ],
      ),
    );
  }
}

// ── Videos Tab (Naats + Bayanat) ─────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final Function(int) onNavTap;
  const _VideosTab({required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (_, favs, __) {
        final allVideos = [...favs.favNaats, ...favs.favBayanat];

        if (allVideos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border_rounded,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No favorite videos yet', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Tap the ♥ heart on any Naat or Bayan to save it here',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GoldButton(
                  label: 'Browse Naats',
                  icon: Icons.music_note_rounded,
                  onTap: () => onNavTap(1),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allVideos.length,
          itemBuilder: (ctx, i) {
            final v = allVideos[i];
            final isNaat = v.type == 'naat';
            return _FavVideoCard(
              video: v,
              isNaat: isNaat,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    video: VideoItem(
                      id: v.id,
                      title: v.title,
                      channelName: v.channelName,
                      thumbnailUrl: v.thumbnailUrl,
                      youtubeVideoId: v.id,
                      category: isNaat ? 'Naat' : 'Bayan',
                    ),
                  ),
                ),
              ),
              onRemove: () {
                if (isNaat) {
                  favs.toggleNaat(v);
                } else {
                  favs.toggleBayan(v);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _FavVideoCard extends StatelessWidget {
  final FavoriteVideo video;
  final bool isNaat;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavVideoCard({
    required this.video,
    required this.isNaat,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.card,
                          child: const Center(
                            child: Icon(Icons.image_rounded,
                                color: AppColors.textMuted),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.card,
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : Container(color: AppColors.card),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isNaat
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                          : const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isNaat ? 'Naat' : 'Bayan',
                      style: AppTextStyles.label.copyWith(
                        color: isNaat
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFFCE93D8),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title + channel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video.channelName,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Remove favorite
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded,
                        color: Colors.redAccent, size: 22),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quran Tab (Favorite Surahs) ───────────────────────────────────────────────
class _QuranTab extends StatefulWidget {
  @override
  State<_QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<_QuranTab> {
  List<Surah> _allSurahs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await QuranService.fetchAllSurahs();
    if (mounted) {
      setState(() {
        _allSurahs = surahs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (_, favs, __) {
        if (_loading) {
          return const Center(child: TasbehLoader());
        }

        final favSurahs = _allSurahs
            .where((s) => favs.isSurahFav(s.number))
            .toList();

        if (favSurahs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_border_rounded,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No favorite Surahs yet',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Tap the bookmark icon on any Surah to save it here',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favSurahs.length,
          itemBuilder: (ctx, i) {
            final s = favSurahs[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SurahDetailScreen(
                    surah: s,
                    selectedReciter: 'ar.alafasy',
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${s.number}',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(s.englishName,
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        s.name,
                        style: AppTextStyles.arabic.copyWith(fontSize: 20),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${s.englishNameTranslation}  •  ${s.numberOfAyahs} Ayahs  •  ${s.revelationType}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_rounded,
                            color: AppColors.gold, size: 22),
                        onPressed: () => favs.toggleSurah(s.number),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Search Screen ─────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  // Mock results - in production this would search across API data
  final List<Map<String, dynamic>> _allResults = [
    {'type': 'Naat', 'title': 'Ya Nabi Salam Alaika', 'sub': 'Saifi TV Official', 'icon': Icons.music_note_rounded},
    {'type': 'Naat', 'title': 'Tajdar e Haram', 'sub': 'Mehfil e Naat', 'icon': Icons.music_note_rounded},
    {'type': 'Bayan', 'title': 'Ilm Ki Fazilat', 'sub': 'Islamic Lectures', 'icon': Icons.record_voice_over_rounded},
    {'type': 'Surah', 'title': 'Al-Fatiha', 'sub': '7 Ayahs • Meccan', 'icon': Icons.menu_book_rounded},
    {'type': 'Surah', 'title': 'Yaseen', 'sub': '83 Ayahs • Meccan', 'icon': Icons.menu_book_rounded},
    {'type': 'Surah', 'title': 'Al-Mulk', 'sub': '30 Ayahs • Meccan', 'icon': Icons.menu_book_rounded},
    {'type': 'Hadith', 'title': 'Hadith on Intention', 'sub': 'Sahih Bukhari', 'icon': Icons.format_quote_rounded},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _allResults;
    return _allResults.where((r) =>
        r['title'].toString().toLowerCase().contains(_query.toLowerCase()) ||
        r['type'].toString().toLowerCase().contains(_query.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              style: AppTextStyles.bodyLarge,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search Naats, Bayanat, Quran, Hadith...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Results
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No results for "$_query"',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final r = _filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.border.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(r['icon'] as IconData,
                                color: AppColors.gold, size: 20),
                          ),
                          title: Text(r['title'] as String,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                          subtitle: Text(r['sub'] as String,
                              style: AppTextStyles.bodySmall),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.gold.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r['type'] as String,
                                style: AppTextStyles.goldSmall),
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Privacy Policy Screen ─────────────────────────────────────────────────────
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Legal'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy Policy', style: AppTextStyles.headingMedium),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'Saifi TV respects your privacy. We collect only necessary data to improve your experience:\n\n'
                    '• Location: Used only for Prayer Times and Qibla compass. Not stored remotely or shared beyond necessary API calculations.\n\n'
                    '• Local Storage: Favorites, Zikr counts, and settings are stored only on your device.\n\n'
                    '• Content: Videos are listed via YouTube API Services and played with YouTube’s official embed player (YouTube controls and branding). We do not download, rehost, or strip audio.\n\n'
                    'By using this application to watch videos, you agree to be bound by the YouTube Terms of Service.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      children: [
                        const TextSpan(text: 'Full policy (hosted): '),
                        TextSpan(
                          text: 'Open Privacy Policy',
                          style: const TextStyle(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _open(AppUrls.privacyPolicy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      children: [
                        TextSpan(
                          text: 'YouTube Terms of Service',
                          style: const TextStyle(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _open(AppUrls.youtubeTerms),
                        ),
                        const TextSpan(text: '  ·  '),
                        TextSpan(
                          text: 'Google Privacy Policy',
                          style: const TextStyle(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _open(AppUrls.googlePrivacy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Content Takedown', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'If you believe any content on Saifi TV violates your rights, please contact us at: ${AppUrls.supportEmail}\n\nWe will review and remove content within 48 hours.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terms of Use', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'By using Saifi TV, you agree to use the app for personal, non-commercial Islamic learning and spiritual purposes only. Redistribution of content without permission is prohibited.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── About & Credits Screen ───────────────────────────────────────────────────
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About & Credits'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Disclaimer Card (always visible) ──────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D5338), Color(0xFF122A1E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withOpacity(0.22),
                          AppColors.gold.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.gold.withOpacity(0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_rounded,
                            color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'اہم اطلاع',
                          style: AppTextStyles.goldText.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  // body text
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        kDisclaimerText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          height: 1.85,
                          fontSize: 15,
                          fontFamily: 'Amiri',
                          color: const Color(0xFFE8E8E8),
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saifi TV', style: AppTextStyles.headingMedium),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'An Islamic application built with the intention of providing authentic Naats, Bayanat, and the Holy Quran for spiritual enrichment.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Credits & Attribution', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'The Holy Quran texts, translations, and audio recitations in this app are provided by:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AlQuran.Cloud API (alquran.cloud)',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Translations are proudly provided by the original translators, such as Maulana Fateh Muhammad Jalandhari, and other respected scholars. Audio recitations are the copyright of their respective reciters. This application does not claim ownership of the Quranic content.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open Source Libraries', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'Developed using the Flutter Framework and various open-source packages including just_audio, provider, and more.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terms of Service', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      children: [
                        const TextSpan(
                          text:
                              'This app uses YouTube API Services. By using our video player, you agree to be bound by the ',
                        ),
                        TextSpan(
                          text: 'YouTube Terms of Service',
                          style: const TextStyle(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(
                                  Uri.parse(AppUrls.youtubeTerms),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Google Privacy Policy',
                          style: const TextStyle(
                            color: AppColors.gold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(
                                  Uri.parse(AppUrls.googlePrivacy),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Notification Settings Screen ──────────────────────────────────────────────
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  int _minutesBefore = 15;
  bool _jummah = true;
  bool _hadith = true;
  bool _zikr = true;
  bool _newVideo = true;
  final Map<String, bool> _prayers = {
    for (final k in NotificationService.prayerKeys) k: true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _minutesBefore = await NotificationService.getMinutesBefore();
    _jummah = await NotificationService.isEnabled(NotificationService.prefJummah);
    _hadith = await NotificationService.isEnabled(NotificationService.prefHadith);
    _zikr = await NotificationService.isEnabled(NotificationService.prefZikr);
    _newVideo =
        await NotificationService.isEnabled(NotificationService.prefNewVideo);
    for (final key in NotificationService.prayerKeys) {
      _prayers[key] = await NotificationService.isPrayerEnabled(key);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshSchedules() async {
    await NotificationService.refreshAllSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prayer Reminders', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Namaz se kitni der pehle alert chahiye?',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [5, 10, 15, 20, 30].map((m) {
                            final selected = _minutesBefore == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${m}m'),
                                selected: selected,
                                selectedColor: AppColors.gold.withOpacity(0.3),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? AppColors.gold
                                      : AppColors.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) async {
                                  setState(() => _minutesBefore = m);
                                  await NotificationService.setMinutesBefore(m);
                                  await _refreshSchedules();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const GoldDivider(),
                      ...NotificationService.prayerKeys.map((key) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            NotificationService.prayerLabels[key]!,
                            style: AppTextStyles.bodyMedium,
                          ),
                          value: _prayers[key] ?? true,
                          activeColor: AppColors.gold,
                          onChanged: (v) async {
                            setState(() => _prayers[key] = v);
                            await NotificationService.setPrayerEnabled(key, v);
                            await _refreshSchedules();
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Jummah Reminder',
                            style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                          'Friday — Surah Kahf parhne ki yaad',
                          style: AppTextStyles.bodySmall,
                        ),
                        value: _jummah,
                        activeColor: AppColors.gold,
                        onChanged: (v) async {
                          setState(() => _jummah = v);
                          await NotificationService.setEnabled(
                              NotificationService.prefJummah, v);
                          await NotificationService.scheduleJummahReminder();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Daily Hadith',
                            style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                          'Subah 7 AM — Aaj ka Hadith ready hai',
                          style: AppTextStyles.bodySmall,
                        ),
                        value: _hadith,
                        activeColor: AppColors.gold,
                        onChanged: (v) async {
                          setState(() => _hadith = v);
                          await NotificationService.setEnabled(
                              NotificationService.prefHadith, v);
                          await NotificationService.scheduleHadithReminder();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Zikr Reminder',
                            style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                          'Shaam ko agar daily target incomplete ho',
                          style: AppTextStyles.bodySmall,
                        ),
                        value: _zikr,
                        activeColor: AppColors.gold,
                        onChanged: (v) async {
                          setState(() => _zikr = v);
                          await NotificationService.setEnabled(
                              NotificationService.prefZikr, v);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('New Video Alerts',
                            style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                          'Har 60 min approved channels check',
                          style: AppTextStyles.bodySmall,
                        ),
                        value: _newVideo,
                        activeColor: AppColors.gold,
                        onChanged: (v) async {
                          setState(() => _newVideo = v);
                          await NotificationService.setEnabled(
                              NotificationService.prefNewVideo, v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manual Check', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Abhi new videos check karein (normally har 60 minutes automatic).',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checking for new videos...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            await NotificationService.checkForNewVideos();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Check complete. New video mile to notification aayegi.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.cloud_download_rounded,
                              color: AppColors.gold),
                          label: Text(
                            'Check New Videos Now',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.gold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.gold),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
