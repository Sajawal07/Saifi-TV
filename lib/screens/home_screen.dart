import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/api_constants.dart';
import '../models/app_models.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/disclaimer_dialog.dart';
import 'misc_screens.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavTap;
  const HomeScreen({super.key, required this.onNavTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VideoItem> _featuredNaats = [];
  PrayerTimes? _prayerTimes;
  HadithItem? _hadith;
  bool _loading = true;
  bool _locationError = false;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // New key so users who only saw the old disclaimer also accept YouTube ToS
    final bool hasAcceptedLegal =
        prefs.getBool('hasAcceptedLegalTerms') ?? false;
    if (!hasAcceptedLegal && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final accepted = await showDisclaimerDialog(context);
      if (accepted) {
        await prefs.setBool('hasAcceptedLegalTerms', true);
        await prefs.setBool('hasSeenDisclaimer', true);
      }
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final naats = await YouTubeService.fetchApprovedChannels(
      channels: ApiConstants.approvedNaatChannels,
      contentFilter: 'naat',
      hardLimitPerChannel: 30,
    );
    final hadith = await HadithService.fetchDailyHadith();
    final prayerData = await PrayerTimesService.fetchPrayerData(forceRefresh: forceRefresh);

    if (mounted) {
      setState(() {
        _featuredNaats = naats.take(4).toList();
        _hadith = hadith;
        _prayerTimes = prayerData.times;
        _locationError = prayerData.locationError;
        _locationName = prayerData.locationName;
        _loading = false;
      });
    }

    if (prayerData.times != null) {
      await NotificationService.schedulePrayerReminders(prayerData.times!);
    }
    // Evening zikr nudge when app is opened near reminder hour
    await NotificationService.checkZikrReminder();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      // App settings opened, when they come back we could refresh, but user can pull to refresh.
      return;
    }
    
    final requested = await Geolocator.requestPermission();
    if (requested == LocationPermission.whileInUse || requested == LocationPermission.always) {
       setState(() { _loading = true; });
       _loadData(); // Refresh to get exact location
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => _loadData(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.backgroundDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Image.asset(
                    'assets/images/header.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Prayer Times Banner ─────────────────────────────
                    _buildPrayerBanner(),
                    const SizedBox(height: 24),

                    // ── Quick Access Grid ────────────────────────────────
                    SectionHeader(title: 'Quick Access'),
                    _buildQuickAccessGrid(),
                    const SizedBox(height: 24),

                    // ── Featured Naats ───────────────────────────────────
                    SectionHeader(
                      title: 'Featured Naats',
                      action: 'See All',
                      onAction: () => widget.onNavTap(1),
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturedNaats(),
                    const SizedBox(height: 24),

                    // ── Daily Hadith ─────────────────────────────────────
                    _buildHadithCard(),
                    const SizedBox(height: 24),

                    // ── Coming Soon ──────────────────────────────────────
                    _buildComingSoonBanner(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentPrayerIndex() {
    if (_prayerTimes == null) return -1;
    final now = DateTime.now();

    DateTime parseTime(String t) {
      try {
        final timeString = t.split(' ')[0];
        final parts = timeString.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        return DateTime(now.year, now.month, now.day, hour, min);
      } catch (e) {
        return now.subtract(const Duration(hours: 1)); // safe fallback
      }
    }

    final prayers = [
      parseTime(_prayerTimes!.fajr),
      parseTime(_prayerTimes!.dhuhr),
      parseTime(_prayerTimes!.asr),
      parseTime(_prayerTimes!.maghrib),
      parseTime(_prayerTimes!.isha),
    ];

    for (int i = 0; i < prayers.length; i++) {
      if (prayers[i].isAfter(now)) {
        return i == 0 ? 4 : i - 1;
      }
    }
    return 4; // After Isha
  }

  String _getNextPrayerText() {
    if (_prayerTimes == null) return 'Calculating...';
    
    final now = DateTime.now();
    
    DateTime parseTime(String t) {
      try {
        final timeString = t.split(' ')[0];
        final parts = timeString.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        return DateTime(now.year, now.month, now.day, hour, min);
      } catch (e) {
        return now.subtract(const Duration(hours: 1)); // safe fallback
      }
    }

    final prayers = [
      {'name': 'Fajr', 'time': parseTime(_prayerTimes!.fajr)},
      {'name': 'Dhuhr', 'time': parseTime(_prayerTimes!.dhuhr)},
      {'name': 'Asr', 'time': parseTime(_prayerTimes!.asr)},
      {'name': 'Maghrib', 'time': parseTime(_prayerTimes!.maghrib)},
      {'name': 'Isha', 'time': parseTime(_prayerTimes!.isha)},
    ];

    for (final p in prayers) {
      final time = p['time'] as DateTime;
      if (time.isAfter(now)) {
        final diff = time.difference(now);
        return '${p['name']} in ${diff.inHours}h ${diff.inMinutes % 60}m';
      }
    }
    
    final fajrTomorrow = (prayers[0]['time'] as DateTime).add(const Duration(days: 1));
    final diff = fajrTomorrow.difference(now);
    return 'Fajr in ${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Widget _buildPrayerBanner() {
    if (_loading) {
      return ShimmerBox(width: double.infinity, height: 100, borderRadius: 16);
    }

    String formatTime12Hour(String? t) {
      if (t == null || t == '--:--') return '--:--';
      try {
        final timeString = t.split(' ')[0];
        final parts = timeString.split(':');
        final hour24 = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        
        final ampm = hour24 >= 12 ? 'PM' : 'AM';
        final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
        
        final minStr = min.toString().padLeft(2, '0');
        return '$hour12:$minStr $ampm';
      } catch (e) {
        return t;
      }
    }

    final prayers = [
      {'name': 'Fajr', 'time': formatTime12Hour(_prayerTimes?.fajr), 'icon': Icons.wb_twilight_rounded},
      {'name': 'Dhuhr', 'time': formatTime12Hour(_prayerTimes?.dhuhr), 'icon': Icons.wb_sunny_rounded},
      {'name': 'Asr', 'time': formatTime12Hour(_prayerTimes?.asr), 'icon': Icons.wb_sunny_outlined},
      {'name': 'Maghrib', 'time': formatTime12Hour(_prayerTimes?.maghrib), 'icon': Icons.nightlight_round_outlined},
      {'name': 'Isha', 'time': formatTime12Hour(_prayerTimes?.isha), 'icon': Icons.bedtime_rounded},
    ];

    return GestureDetector(
      onTap: () => widget.onNavTap(5),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Prayer Times', style: AppTextStyles.goldText.copyWith(fontSize: 14)),
                    Text(_getNextPrayerText(), style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: prayers.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isCurrent = idx == _getCurrentPrayerIndex();

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isCurrent
                        ? BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                          )
                        : null,
                    child: Column(
                      children: [
                        Icon(p['icon'] as IconData, size: 16, color: AppColors.gold),
                        const SizedBox(height: 4),
                        Text(p['name'] as String, style: AppTextStyles.label.copyWith(fontSize: 11, color: const Color(0xFFF5F5F5)), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(p['time'] as String,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_locationError) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _requestLocationPermission,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location off. Times shown for $_locationName. Tap to enable.',
                          style: AppTextStyles.label.copyWith(color: Colors.redAccent, fontSize: 11)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      {'icon': Icons.music_note_rounded, 'label': 'Naats', 'index': 1, 'color': const Color(0xFF2E7D32)},
      {'icon': Icons.record_voice_over_rounded, 'label': 'Bayanat', 'index': 2, 'color': const Color(0xFF6A1B9A)},
      {'icon': Icons.menu_book_rounded, 'label': 'Quran', 'index': 3, 'color': const Color(0xFF0277BD)},
      {
        'image': 'assets/images/zikr.png',
        'label': 'Zikr',
        'index': 4,
        'color': const Color(0xFFC9A84E),
      },
      {'icon': Icons.explore_rounded, 'label': 'Qibla', 'index': 6, 'color': const Color(0xFFAD1457)},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar', 'index': 7, 'color': const Color(0xFF00695C)},
      {'icon': Icons.format_quote_rounded, 'label': 'Hadith', 'index': 8, 'color': const Color(0xFF4527A0)},
      {'icon': Icons.favorite_rounded, 'label': 'Favorites', 'index': 9, 'color': const Color(0xFFB71C1C)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final imagePath = item['image'] as String?;
        return GestureDetector(
          onTap: () => widget.onNavTap(item['index'] as int),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imagePath != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(imagePath, fit: BoxFit.contain),
                        )
                      : Icon(
                          item['icon'] as IconData,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label'] as String,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildFeaturedNaats() {
    if (_loading) {
      return SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ShimmerBox(width: 200, height: 200),
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredNaats.length,
        itemBuilder: (ctx, i) {
          final naat = _featuredNaats[i];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: VideoCard(
              title: naat.title,
              channelName: naat.channelName,
              thumbnailUrl: naat.thumbnailUrl,
              onTap: () => widget.onNavTap(1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHadithCard() {
    if (_loading || _hadith == null) {
      return ShimmerBox(width: double.infinity, height: 160);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('Hadith of the Day', style: AppTextStyles.headingSmall),
            ],
          ),
          const GoldDivider(),
          const SizedBox(height: 8),
          Text(
            _hadith!.text,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          if (_hadith!.narrator != null)
            Text(
              '— ${_hadith!.narrator}',
              style: AppTextStyles.goldSmall.copyWith(fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 4),
          Text(
            _hadith!.bookName,
            style: AppTextStyles.label.copyWith(color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D5338), Color(0xFF163D29)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_rounded, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Islamic Shop', style: AppTextStyles.headingSmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Coming Soon',
                          style: AppTextStyles.label.copyWith(color: AppColors.buttonText)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Halal products, Islamic books & more',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
