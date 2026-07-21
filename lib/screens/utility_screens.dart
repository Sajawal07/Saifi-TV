import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hijri/hijri_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/app_models.dart';
import '../services/api_services.dart';
import '../widgets/common_widgets.dart';

// ── Prayer Times Screen ───────────────────────────────────────────────────────
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimes? _times;
  bool _loading = true;
  String _cityName = 'Detecting location...';
  String _hijriDate = '';
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
    _setHijriDate();
  }

  void _setHijriDate() {
    final hijri = HijriCalendar.now();
    setState(() {
      _hijriDate = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    });
  }

  Future<void> _fetchPrayerTimes({bool forceRefresh = false}) async {
    final data = await PrayerTimesService.fetchPrayerData(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _times = data.times;
        _cityName = data.locationName;
        _locationError = data.locationError;
        _loading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    
    final requested = await Geolocator.requestPermission();
    if (requested == LocationPermission.whileInUse || requested == LocationPermission.always) {
       setState(() { _loading = true; });
       _fetchPrayerTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      {'name': 'Fajr', 'time': formatTime12Hour(_times?.fajr), 'icon': Icons.wb_twilight_rounded, 'arabic': 'فجر'},
      {'name': 'Sunrise', 'time': formatTime12Hour(_times?.sunrise), 'icon': Icons.wb_sunny_rounded, 'arabic': 'طلوع'},
      {'name': 'Dhuhr', 'time': formatTime12Hour(_times?.dhuhr), 'icon': Icons.light_mode_rounded, 'arabic': 'ظہر'},
      {'name': 'Asr', 'time': formatTime12Hour(_times?.asr), 'icon': Icons.wb_cloudy_rounded, 'arabic': 'عصر'},
      {'name': 'Maghrib', 'time': formatTime12Hour(_times?.maghrib), 'icon': Icons.nightlight_outlined, 'arabic': 'مغرب'},
      {'name': 'Isha', 'time': formatTime12Hour(_times?.isha), 'icon': Icons.bedtime_rounded, 'arabic': 'عشاء'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prayer Times'),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _loading = true);
              _fetchPrayerTimes(forceRefresh: true);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: TasbehLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Card
                  GlassCard(
                    child: Column(
                      children: [
                        Text(
                          intl.DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(_hijriDate, style: AppTextStyles.goldText),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(_cityName, style: AppTextStyles.bodySmall),
                          ],
                        ),
                        if (_locationError) ...[
                          const SizedBox(height: 12),
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
                                    child: Text('Location off. Times shown for $_cityName. Tap to enable.',
                                      style: AppTextStyles.label.copyWith(color: Colors.redAccent, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prayer Times Cards
                  ...prayers.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.4)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p['icon'] as IconData,
                              color: AppColors.buttonText, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'] as String,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                              Text(p['arabic'] as String,
                                  style: AppTextStyles.arabic.copyWith(fontSize: 16),
                                  textDirection: TextDirection.rtl),
                            ],
                          ),
                        ),
                        Text(
                          p['time']?.toString() ?? '--:--',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Islamic reminder
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Times shown are calculated for your location. Please verify with your local mosque.',
                            style: AppTextStyles.bodySmall,
                          ),
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

// ── Islamic Calendar Screen ───────────────────────────────────────────────────
class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late HijriCalendar _hijri;

  @override
  void initState() {
    super.initState();
    _hijri = HijriCalendar.now();
  }

  static const Map<int, String> _islamicMonths = {
    1: 'Muharram', 2: 'Safar', 3: "Rabi' al-Awwal",
    4: "Rabi' al-Thani", 5: "Jumada al-Awwal", 6: "Jumada al-Thani",
    7: 'Rajab', 8: "Sha'ban", 9: 'Ramadan',
    10: 'Shawwal', 11: "Dhul-Qa'da", 12: "Dhul-Hijja",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Hijri date
            GlassCard(
              child: Column(
                children: [
                  Text(
                    '${_hijri.hDay}',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.gold,
                      fontSize: 72,
                    ),
                  ),
                  Text(
                    _islamicMonths[_hijri.hMonth] ?? _hijri.longMonthName,
                    style: AppTextStyles.headingLarge,
                  ),
                  Text(
                    '${_hijri.hYear} AH',
                    style: AppTextStyles.goldText,
                  ),
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'Gregorian: ${intl.DateFormat('MMMM d, y').format(DateTime.now())}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SectionHeader(title: 'Islamic Months'),
            const SizedBox(height: 12),

            // Months grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.0,
              ),
              itemCount: 12,
              itemBuilder: (ctx, i) {
                final month = i + 1;
                final isCurrentMonth = month == _hijri.hMonth;
                return Container(
                  decoration: BoxDecoration(
                    gradient: isCurrentMonth
                        ? AppColors.goldGradient
                        : AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentMonth
                          ? AppColors.gold
                          : AppColors.border.withOpacity(0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$month.',
                        style: isCurrentMonth
                            ? AppTextStyles.button.copyWith(fontSize: 12)
                            : AppTextStyles.bodySmall,
                      ),
                      Text(
                        _islamicMonths[month] ?? '',
                        style: isCurrentMonth
                            ? AppTextStyles.button.copyWith(fontSize: 13)
                            : AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Daily Hadith Screen ───────────────────────────────────────────────────────
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  HadithItem? _hadith;
  bool _loading = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await HadithService.fetchDailyHadith();
    if (mounted) setState(() { _hadith = h; _loading = false; });
  }

  Future<void> _shareHadith() async {
    if (_hadith == null) return;

    // Show preview dialog first
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The card to be shared
            Screenshot(
              controller: _screenshotController,
              child: _HadithShareCard(hadith: _hadith!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _captureAndShare();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: Color(0xFF1A1A1A), size: 18),
                          SizedBox(width: 8),
                          Text('Share', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare() async {
    try {
      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/hadith_saifitv.png').writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${_hadith!.bookReference ?? 'Hadith No. ${_hadith!.id}'}\n\n${_hadith!.text}\n\n— ${_hadith!.narrator ?? ''}\n\nSaifi TV – Ahl-e-Sunnat wal Jamaat',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Hadith'),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.gold),
            onPressed: _hadith != null ? _shareHadith : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: TasbehLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Book badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _hadith?.bookName ?? 'Sahih Al-Bukhari',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Hadith text
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_quote_rounded,
                                color: AppColors.gold, size: 28),
                            const SizedBox(width: 8),
                            Text(_hadith?.bookReference ?? 'Hadith No. ${_hadith?.id ?? ''}',
                                style: AppTextStyles.headingSmall),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const GoldDivider(),
                        const SizedBox(height: 16),
                        if (_hadith?.arabicText != null) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _hadith!.arabicText!,
                              style: AppTextStyles.arabicLarge.copyWith(height: 1.8),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const GoldDivider(),
                          const SizedBox(height: 16),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _hadith?.text ?? '',
                            style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        if (_hadith?.narrator != null) ...[
                          const SizedBox(height: 16),
                          const GoldDivider(),
                          const SizedBox(height: 12),
                          Text(
                            '— ${_hadith!.narrator}',
                            style: AppTextStyles.goldText.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Share hint
                  GestureDetector(
                    onTap: _shareHadith,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: Color(0xFF1A1A1A), size: 20),
                          SizedBox(width: 10),
                          Text('Share as Beautiful Card', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Islamic note
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hadith sourced from authentic Sahih collections only. Verify with your Islamic scholar.',
                            style: AppTextStyles.bodySmall,
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

// ── Hadith Share Card Widget ──────────────────────────────────────────────────
class _HadithShareCard extends StatelessWidget {
  final HadithItem hadith;
  const _HadithShareCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/hadith_card_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top: Saifi TV branding
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mosque_rounded, color: Color(0xFF1A1A1A), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saifi TV', style: AppTextStyles.goldText.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Ahl-e-Sunnat wal Jamaat', style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gold divider top
                  Container(height: 1, color: AppColors.gold.withOpacity(0.6)),
                  const SizedBox(height: 20),

                  // Hadith number badge
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                      ),
                      child: Text(
                        hadith.bookReference ?? 'حدیث نمبر ${hadith.id}',
                        style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 12),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Urdu Hadith text (main content)
                  Text(
                    hadith.text,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: Colors.white,
                      height: 2.0,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 20),

                  // Gold divider bottom
                  Container(height: 1, color: AppColors.gold.withOpacity(0.6)),
                  const SizedBox(height: 14),

                  // Narrator (Ravi)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${hadith.narrator ?? ''}',
                      style: AppTextStyles.goldSmall.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      hadith.bookName,
                      style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11),
                      textDirection: TextDirection.rtl,
                    ),
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

