import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/api_constants.dart';
import '../core/providers/app_providers.dart';
import '../models/app_models.dart';
import '../services/api_services.dart';
import '../widgets/common_widgets.dart';
import '../widgets/youtube_embed_player.dart';

// ── Naats List Screen ─────────────────────────────────────────────────────────
class NaatsScreen extends StatefulWidget {
  const NaatsScreen({super.key});

  @override
  State<NaatsScreen> createState() => _NaatsScreenState();
}

class _NaatsScreenState extends State<NaatsScreen> {
  List<VideoItem> _videos = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  bool _searchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Naat',
    'Mehfil',
    'Urs',
    'Ramzan Special',
    'Milad',
    'Hamd',
    'Salaam',
    'Manqabat',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final videos = await YouTubeService.fetchApprovedChannels(
      channels: ApiConstants.approvedNaatChannels,
      contentFilter: 'naat',
    );
    if (mounted) {
      setState(() {
        _videos = videos;
        _loading = false;
      });
    }
  }

  List<VideoItem> get _filteredVideos {
    final q = _searchQuery.trim().toLowerCase();
    // While searching, look across all naats (ignore category chips)
    var list = (q.isNotEmpty || _selectedCategory == 'All')
        ? _videos
        : _videos.where((v) => v.category == _selectedCategory).toList();
    if (q.isEmpty) return list;
    return list
        .where(
          (v) =>
              v.title.toLowerCase().contains(q) ||
              v.channelName.toLowerCase().contains(q) ||
              v.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Naats'),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.gold,
            ),
            onPressed: () {
              setState(() {
                if (_searchOpen) {
                  _searchOpen = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _searchOpen = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Container(
              width: double.infinity,
              color: AppColors.backgroundDark,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.gold,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Naat, channel, ya category search...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.gold,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.gold.withOpacity(0.35),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.gold.withOpacity(0.35),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          // Categories (hidden while actively searching for clearer results)
          if (!_searchOpen || _searchQuery.isEmpty)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                itemBuilder:
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: _categories[i],
                        isSelected: _selectedCategory == _categories[i],
                        onTap:
                            () => setState(
                              () => _selectedCategory = _categories[i],
                            ),
                      ),
                    ),
              ),
            ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredVideos.length} result${_filteredVideos.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          // Video Grid
          Expanded(
            child:
                _loading
                    ? const Center(child: TasbehLoader())
                    : Builder(
                      builder: (ctx) {
                        final filteredVideos = _filteredVideos;

                        if (filteredVideos.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No naats found for "$_searchQuery"'
                                    : 'No videos found in this category',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.80,
                              ),
                          itemCount: filteredVideos.length,
                          itemBuilder: (ctx, i) {
                            final v = filteredVideos[i];
                            return Consumer<FavoritesProvider>(
                              builder:
                                  (_, favs, __) => VideoCard(
                                    title: v.title,
                                    channelName: v.channelName,
                                    thumbnailUrl: v.thumbnailUrl,
                                    isFavorite: favs.isNaatFav(v.id),
                                    onFavorite: () => favs.toggleNaat(FavoriteVideo(
                                      id: v.id,
                                      title: v.title,
                                      channelName: v.channelName,
                                      thumbnailUrl: v.thumbnailUrl,
                                      type: 'naat',
                                    )),
                                    onTap:
                                        () => Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    VideoPlayerScreen(video: v),
                                          ),
                                        ),
                                  ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ── Bayanat Screen ────────────────────────────────────────────────────────────
class BayanatScreen extends StatefulWidget {
  const BayanatScreen({super.key});

  @override
  State<BayanatScreen> createState() => _BayanatScreenState();
}

class _BayanatScreenState extends State<BayanatScreen> {
  List<VideoItem> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final videos = await YouTubeService.fetchApprovedChannels(
      channels: ApiConstants.approvedBayanatChannels,
      contentFilter: 'bayan',
    );
    if (mounted) {
      setState(() {
        _videos = videos;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bayanat'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body:
          _loading
              ? const Center(child: TasbehLoader())
              : _videos.isEmpty
              ? Center(
                  child: Text(
                    'No bayanat found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _videos.length,
                itemBuilder: (ctx, i) {
                  final v = _videos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Consumer<FavoritesProvider>(
                      builder:
                          (_, favs, __) => VideoCard(
                            title: v.title,
                            channelName: v.channelName,
                            thumbnailUrl: v.thumbnailUrl,
                            isFavorite: favs.isBayanFav(v.id),
                            onFavorite: () => favs.toggleBayan(FavoriteVideo(
                              id: v.id,
                              title: v.title,
                              channelName: v.channelName,
                              thumbnailUrl: v.thumbnailUrl,
                              type: 'bayan',
                            )),
                            onTap:
                                () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => VideoPlayerScreen(video: v),
                                  ),
                                ),
                          ),
                    ),
                  );
                },
              ),
    );
  }
}

// ── YouTube Video Player Screen ──────────────────────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // All available zikr options with their colors
  static const List<Map<String, dynamic>> _zikrOptions = [
    {'key': 'qalb', 'name': 'Qalb', 'arabic': 'قلب', 'color': 0xFFE6C84A},
    {'key': 'ruh', 'name': 'Ruh', 'arabic': 'روح', 'color': 0xFFE53935},
    {'key': 'sirri', 'name': 'Sirri', 'arabic': 'سِر', 'color': 0xFFF5F3E7},
    {'key': 'khaffi', 'name': 'Khaffi', 'arabic': 'خَفی', 'color': 0xFF212121},
    {'key': 'akhfa', 'name': 'Akhfa', 'arabic': 'اَخفیٰ', 'color': 0xFF2E7D32},
    {'key': 'nufs', 'name': 'Nafs', 'arabic': 'نفس', 'color': 0xFFF5F3E7},
    {
      'key': 'sultan',
      'name': 'Sultan',
      'arabic': 'سُلطان',
      'color': 0xFFFFD700,
    },
    {
      'key': 'nafi_asbat',
      'name': 'Nafi Asbat',
      'arabic': 'لَا إِلٰهَ إِلَّا اللّٰه',
      'color': 0xFFC9A84E,
    },
  ];

  String _selectedKey = 'nafi_asbat';

  Map<String, dynamic> get _selected =>
      _zikrOptions.firstWhere((z) => z['key'] == _selectedKey);

  Color get _selectedColor => Color(_selected['color'] as int);

  Color get _activeTextColor {
    if (_selectedKey == 'khaffi') return Colors.white;
    return _selectedColor;
  }

  Color get _activeIconColor {
    if ([
      'sirri',
      'nufs',
      'qalb',
      'sultan',
      'nafi_asbat',
    ].contains(_selectedKey)) {
      return Colors.black87;
    }
    return Colors.white;
  }

  Color _getChipTextColor(bool isSelected, String key, Color baseColor) {
    if (!isSelected) {
      if (key == 'khaffi') return Colors.white;
      return baseColor;
    }
    if (['sirri', 'nufs', 'qalb', 'sultan', 'nafi_asbat'].contains(key)) {
      return Colors.black87;
    }
    return Colors.white;
  }

  Color _getBorderColor(String key, Color baseColor, {bool isCard = false}) {
    if (key == 'khaffi') {
      return isCard ? Colors.grey.shade700 : Colors.grey.shade500;
    }
    return isCard ? baseColor.withOpacity(0.5) : baseColor;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onZikrTap(ZikrProvider zikr) {
    _pulseController.forward().then((_) => _pulseController.reverse());
    zikr.increment(_selectedKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Column(
        children: [
          // Official YouTube embed (native controls + branding)
          YoutubeEmbedPlayer(videoId: widget.video.youtubeVideoId),
          // Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.video.channelName,
                          style: AppTextStyles.goldText.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  watchOnYouTubeButton(widget.video.youtubeVideoId),
                  const SizedBox(height: 16),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  // Attribution note
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Video YouTube ke official player se chal rahi hai. '
                            'Channel owner ki ijazat se list ki gayi hai. '
                            'YouTube Terms of Service apply hote hain.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(AppUrls.youtubeTerms),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'YouTube Terms of Service',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Zikr Companion ─────────────────────────────────
                  SectionHeader(title: 'Zikr Companion'),
                      const SizedBox(height: 4),
                      Text(
                        'Zikr chunein aur tap kar ke count barhaein',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Zikr selector chips — horizontal scroll
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _zikrOptions.length,
                          itemBuilder: (_, i) {
                            final z = _zikrOptions[i];
                            final isSelected = z['key'] == _selectedKey;
                            final color = Color(z['color'] as int);
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _selectedKey = z['key'] as String,
                                  ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? color
                                          : color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getBorderColor(
                                      z['key'] as String,
                                      color,
                                    ),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  z['name'] as String,
                                  style: AppTextStyles.label.copyWith(
                                    color: _getChipTextColor(
                                      isSelected,
                                      z['key'] as String,
                                      color,
                                    ),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Zikr Counter Card
                      Consumer<ZikrProvider>(
                        builder: (_, zikr, __) {
                          final count = zikr.getCount(_selectedKey);
                          final target = zikr.getTarget(_selectedKey);
                          final progress = (count / target).clamp(0.0, 1.0);
                          final color = _selectedColor;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.18),
                                  color.withOpacity(0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getBorderColor(
                                  _selectedKey,
                                  color,
                                  isCard: true,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        _selected['arabic'] as String,
                                        style: AppTextStyles.arabic.copyWith(
                                          fontSize:
                                              _selectedKey == 'nafi_asbat'
                                                  ? 24
                                                  : 32,
                                          height: 1.4,
                                          color: _activeTextColor,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selected['name'] as String,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: InteractiveTasbeh(
                                      count: count,
                                      target: target,
                                      beadCount: 33,
                                      size: 180,
                                      beadColor: Colors.white.withOpacity(0.15),
                                      activeBeadColor: color,
                                      stringColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      textColor: _activeTextColor,
                                      onTap: () => _onZikrTap(zikr),
                                    ),
                                  ),
                                ),
                                if (progress >= 1.0) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    '✓  Masha\'Allah! Target complete',
                                    style: AppTextStyles.goldSmall.copyWith(
                                      color: color,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 42),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
