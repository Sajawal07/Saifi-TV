import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/providers/app_providers.dart';
import '../widgets/common_widgets.dart';

// ── Zikr Counter Home ─────────────────────────────────────────────────────────
class ZikrScreen extends StatelessWidget {
  const ZikrScreen({super.key});

  static const List<Map<String, dynamic>> lataif = [
    {
      'key': 'qalb',
      'name': 'Qalb',
      'arabic': 'قلب',
      'location': 'Two fingers below left nipple',
      'prophet': 'Hazrat Adam (A.S)',
      'color': AppColors.qalbColor,
      'textColor': AppColors.buttonText,
      'alignX': 0.25,
      'alignY': -0.1,
    },
    {
      'key': 'ruh',
      'name': 'Ruh',
      'arabic': 'روح',
      'location': 'Two fingers below right nipple',
      'prophet': 'Hazrat Nooh & Ibrahim (A.S)',
      'color': AppColors.ruhColor,
      'textColor': Colors.white,
      'alignX': -0.25,
      'alignY': -0.1,
    },
    {
      'key': 'sirri',
      'name': 'Sirri',
      'arabic': 'سِرّ',
      'location': 'Above the Qalb point',
      'prophet': 'Hazrat Musa (A.S)',
      'color': AppColors.sirriColor,
      'textColor': AppColors.buttonText,
      'alignX': 0.25,
      'alignY': -0.3,
    },
    {
      'key': 'khaffi',
      'name': 'Khaffi',
      'arabic': 'خفی',
      'location': 'Above the Sirri point',
      'prophet': 'Hazrat Isa (A.S)',
      'color': AppColors.khaffiColor,
      'textColor': Colors.white,
      'alignX': -0.25,
      'alignY': -0.3,
    },
    {
      'key': 'akhfa',
      'name': 'Akhfa',
      'arabic': 'أخفى',
      'location': 'Middle of the chest',
      'prophet': 'Hazrat Muhammad ﷺ',
      'color': AppColors.akhfaColor,
      'textColor': Colors.white,
      'alignX': 0.0,
      'alignY': -0.2,
    },
    {
      'key': 'nufs',
      'name': 'Nufs',
      'arabic': 'نفس',
      'location': 'Forehead',
      'prophet': 'Divine Light (Noor)',
      'color': AppColors.nufsColor,
      'textColor': AppColors.buttonText,
      'alignX': 0.0,
      'alignY': -0.7,
    },
    {
      'key': 'sultan',
      'name': 'Sultan-ul-Azkar',
      'arabic': 'سلطان الاذکار',
      'location': 'Top center of the head',
      'prophet': 'Divine Light (Noor)',
      'color': AppColors.sultanColor,
      'textColor': AppColors.buttonText,
      'alignX': 0.0,
      'alignY': -0.9,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Zikr Counter'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Consumer<ZikrProvider>(
        builder:
            (_, zikr, __) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                const IslamicPatternHeader(
                  title: 'Lataif-e-Sitta',
                  subtitle: 'Naqshbandi Tradition — Tap to begin',
                ),
                const SizedBox(height: 16),

                // Lataif cards
                ...lataif.map((l) => _LataifCard(latifa: l, zikr: zikr)),

                const SizedBox(height: 8),
                const GoldDivider(),
                const SizedBox(height: 8),

                // Nafi Asbat
                _NafiAsbatCard(zikr: zikr),
                const SizedBox(height: 30),
              ],
            ),
      ),
    );
  }
}

class _LataifCard extends StatelessWidget {
  final Map<String, dynamic> latifa;
  final ZikrProvider zikr;
  const _LataifCard({required this.latifa, required this.zikr});

  @override
  Widget build(BuildContext context) {
    final key = latifa['key'] as String;
    final color = latifa['color'] as Color;
    final textColor = latifa['textColor'] as Color;
    final count = zikr.getCount(key);
    final target = zikr.getTarget(key);
    final progress = (count / target).clamp(0.0, 1.0);
    final isDone = zikr.isCompleted(key);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ZikrCounterScreen(latifa: latifa),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? color : AppColors.border.withOpacity(0.4),
            width: isDone ? 2 : 1,
          ),
          boxShadow:
              isDone
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)]
                  : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Color indicator + Arabic
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Text(
                  latifa['arabic'] as String,
                  style: AppTextStyles.arabic.copyWith(
                    fontSize: 16,
                    color: textColor,
                    height: 1.2,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        latifa['name'] as String,
                        style: AppTextStyles.headingSmall,
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Done',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    latifa['prophet'] as String,
                    style: AppTextStyles.goldSmall,
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.backgroundDark.withOpacity(0.6),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$count / $target', style: AppTextStyles.bodySmall),
                      if (zikr.getCycles(key) > 0)
                        Text(
                          '${zikr.getCycles(key)} Tasbeeh(s)',
                          style: AppTextStyles.goldSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NafiAsbatCard extends StatelessWidget {
  final ZikrProvider zikr;
  const _NafiAsbatCard({required this.zikr});

  @override
  Widget build(BuildContext context) {
    const key = 'nafi_asbat';
    final count = zikr.getCount(key);
    final target = zikr.getTarget(key);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ZikrCounterScreen(
                    latifa: const {
                      'key': 'nafi_asbat',
                      'name': 'Nafi Asbat',
                      'arabic': 'لَا إِلٰهَ إِلَّا اللّٰه',
                      'location': 'Separate Zikr',
                      'prophet': 'Declaration of Faith',
                      'color': AppColors.background,
                      'textColor': AppColors.gold,
                    },
                  ),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B2A), Color(0xFF1D5338)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 12),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'لَا إِلٰهَ إِلَّا اللّٰه',
              style: AppTextStyles.arabicLarge,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Text('Nafi Asbat', style: AppTextStyles.goldText),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$count / $target', style: AppTextStyles.headingMedium),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Begin', style: AppTextStyles.button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Zikr Counter Active Screen ────────────────────────────────────────────────
class ZikrCounterScreen extends StatefulWidget {
  final Map<String, dynamic> latifa;
  const ZikrCounterScreen({super.key, required this.latifa});

  @override
  State<ZikrCounterScreen> createState() => _ZikrCounterScreenState();
}

class _ZikrCounterScreenState extends State<ZikrCounterScreen> {
  void _onTap(ZikrProvider zikr) async {
    // Vibrate
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib) Vibration.vibrate(duration: 40);
    } catch (_) {
      HapticFeedback.lightImpact();
    }

    zikr.increment(widget.latifa['key'] as String);

    // Check completion
    final key = widget.latifa['key'] as String;
    if (zikr.getCount(key) >= zikr.getTarget(key)) {
      _showCompletionDialog(zikr, key);
    }
  }

  void _showCompletionDialog(ZikrProvider zikr, String key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.gold),
            ),
            title: const Text(
              'Masha\'Allah!',
              style: AppTextStyles.headingMedium,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Target completed for ${widget.latifa['name']}!\nAlhamdulillah!',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  zikr.completeCycle(key);
                  Navigator.pop(context);
                },
                child: Text('Continue', style: AppTextStyles.goldText),
              ),
            ],
          ),
    );
  }

  void _showTargetDialog(ZikrProvider zikr) {
    final key = widget.latifa['key'] as String;
    final controller = TextEditingController(text: '${zikr.getTarget(key)}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom +
                  24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set Target', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                // Preset chips
                Row(
                  children:
                      [100, 500, 1000, 3000]
                          .map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  zikr.setTarget(key, n);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$n',
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                // Custom input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(labelText: 'Custom Target'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'Set Custom Target',
                    onTap: () {
                      final v = int.tryParse(controller.text);
                      if (v != null && v > 0) {
                        zikr.setTarget(key, v);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.latifa['color'] as Color;
    final textColor = widget.latifa['textColor'] as Color;
    final key = widget.latifa['key'] as String;

    return Consumer<ZikrProvider>(
      builder: (_, zikr, __) {
        final count = zikr.getCount(key);
        final target = zikr.getTarget(key);
        final cycles = zikr.getCycles(key);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor.withOpacity(0.8),
            elevation: 0,
            title: Text(
              widget.latifa['name'] as String,
              style: AppTextStyles.headingMedium.copyWith(color: textColor),
            ),
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: textColor),
                onPressed: () => _showTargetDialog(zikr),
                tooltip: 'Set Target',
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: textColor),
                onPressed: () => zikr.reset(key),
                tooltip: 'Reset',
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header (Arabic + Prophet + Badge)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.latifa['arabic'] as String,
                        style: AppTextStyles.arabicLarge.copyWith(
                          fontSize: 40,
                          color: textColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.latifa['prophet'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      if (cycles > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: textColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: bgColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$cycles Tasbeeh Completed',
                                style: TextStyle(
                                  color: bgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Tasbeh Beads Counter ─────────────────────────────────
                  _TasbehBeadsCounter(
                    count: count,
                    target: target,
                    beadColor: textColor,
                    bgColor: bgColor,
                    zikrName: widget.latifa['name'] as String,
                    onTap: () => _onTap(zikr),
                  ),

                  // Bottom Zikr Details Button
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: 'View Zikr Details',
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ZikrDetailScreen(latifa: widget.latifa),
                          ),
                        );
                      },
                    ),
                  ),
                ], // closes Column children list
              ), // closes Column
            ), // closes Padding
          ), // closes SafeArea (body)
        ); // closes Scaffold (return)
      },
    ); // closes Consumer
  }
}

// ── Zikr Details Screen ───────────────────────────────────────────────────────
class ZikrDetailScreen extends StatelessWidget {
  final Map<String, dynamic> latifa;
  const ZikrDetailScreen({super.key, required this.latifa});

  static const Map<String, String> _details = {
    'qalb':
        'یہ لطیفہ بائیں چھاتی کے دو انگلی نیچے ہوتا ہے۔ اس کا رنگ زرد (Yellow) ہے۔ اس کا تعلق حضرت آدم علیہ السلام سے ہے۔ اس کا ذکر کرنے سے دل دنیا کی محبت سے پاک ہو کر اللہ کی محبت میں غرق ہو جاتا ہے۔',
    'ruh':
        'یہ لطیفہ دائیں چھاتی کے دو انگلی نیچے ہوتا ہے۔ اس کا رنگ سرخ (Red) ہے۔ اس کا تعلق حضرت نوح اور حضرت ابراہیم علیہما السلام سے ہے۔ اس کے ذکر سے غصہ اور تکبر ختم ہوتا ہے اور اخلاق اچھے ہوتے ہیں۔',
    'sirri':
        'یہ لطیفہ بائیں چھاتی پر قلب کے اوپر ہوتا ہے۔ اس کا رنگ سفید (White) ہے۔ اس کا تعلق حضرت موسیٰ علیہ السلام سے ہے۔ اس کے ذکر سے انسان کے اندر سے حرص اور لالچ ختم ہو جاتی ہے۔',
    'khaffi':
        'یہ لطیفہ دائیں چھاتی پر روح کے اوپر ہوتا ہے۔ اس کا رنگ سیاہ (Black) ہے۔ اس کا تعلق حضرت عیسیٰ علیہ السلام سے ہے۔ اس کے ذکر سے حسد اور بغض جیسی بیماریاں ختم ہوتی ہیں۔',
    'akhfa':
        'یہ لطیفہ سینے کے بالکل درمیان میں ہوتا ہے۔ اس کا رنگ سبز (Green) ہے۔ اس کا تعلق ہمارے پیارے نبی حضرت محمد ﷺ سے ہے۔ اس کے ذکر سے انسان کے اندر فخر اور ریاکاری ختم ہوتی ہے اور اللہ کا قرب نصیب ہوتا ہے۔',
    'nufs':
        'یہ لطیفہ پیشانی (ماتھے) پر ہوتا ہے۔ اس کا تعلق نفسِ امارہ کو نفسِ مطمئنہ میں بدلنے سے ہے۔ اس کے ذکر سے برے خیالات اور نفسانی خواہشات پر قابو پایا جاتا ہے۔',
    'sultan':
        'یہ سر کے بالکل اوپری حصے (تالو) میں ہوتا ہے۔ جب یہ ذکر جاری ہو جاتا ہے تو انسان کا پورا جسم اور ہر بال اللہ کے ذکر میں شامل ہو جاتا ہے۔',
    'nafi_asbat':
        'نفی اثبات کا ذکر "لَا إِلٰهَ إِلَّا اللّٰه" ہے۔ اس کا مقصد دل سے ہر غیر اللہ کی محبت کو نکال کر صرف اللہ کی محبت کو بسانا ہے۔ یہ ذکر تمام ذکروں کی جان ہے۔',
  };

  @override
  Widget build(BuildContext context) {
    final key = latifa['key'] as String;
    final detailText = _details[key] ?? 'مزید تفصیلات جلد شامل کی جائیں گی۔';

    String imageName = '$key.webp';
    if (key == 'nafi_asbat') imageName = 'nafi asbat.webp';
    if (key == 'nufs') imageName = 'nafs.webp';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${latifa['name']} Details'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/$imageName',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Details Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    latifa['arabic'] as String,
                    style: AppTextStyles.arabicLarge.copyWith(
                      fontSize: 32,
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  const GoldDivider(),
                  const SizedBox(height: 16),
                  Text(
                    detailText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      height: 1.8,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
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

// ── Tasbeh Beads Counter Widget ───────────────────────────────────────────────
class _TasbehBeadsCounter extends StatefulWidget {
  final int count;
  final int target;
  final Color beadColor;
  final Color bgColor;
  final String zikrName;
  final VoidCallback onTap;

  const _TasbehBeadsCounter({
    required this.count,
    required this.target,
    required this.beadColor,
    required this.bgColor,
    required this.zikrName,
    required this.onTap,
  });

  @override
  State<_TasbehBeadsCounter> createState() => _TasbehBeadsCounterState();
}

class _TasbehBeadsCounterState extends State<_TasbehBeadsCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward().then((_) => _pulseController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zikr name label above the beads
        Text(
          widget.zikrName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.beadColor.withValues(alpha: 0.85),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),

        // Beads circle
        ScaleTransition(
          scale: _pulseAnim,
          child: InteractiveTasbeh(
            count: widget.count,
            target: widget.target,
            beadCount: 33,
            size: 280,
            beadColor: widget.beadColor.withValues(alpha: 0.15),
            activeBeadColor: widget.beadColor,
            stringColor: widget.beadColor.withValues(alpha: 0.1),
            textColor: widget.beadColor,
            onTap: _handleTap,
          ),
        ),
      ],
    );
  }
}
