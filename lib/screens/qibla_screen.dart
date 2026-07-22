import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../widgets/common_widgets.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _deviceSupport = false;
  bool _locationError = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final support = await FlutterQiblah.androidDeviceSensorSupport() ?? false;
    bool locationEnabled = false;
    
    if (support) {
      final locationStatus = await FlutterQiblah.checkLocationStatus();
      if (locationStatus.enabled && (locationStatus.status == LocationPermission.always || locationStatus.status == LocationPermission.whileInUse)) {
        locationEnabled = true;
      } else {
        await FlutterQiblah.requestPermissions();
        final newStatus = await FlutterQiblah.checkLocationStatus();
        locationEnabled = newStatus.enabled && (newStatus.status == LocationPermission.always || newStatus.status == LocationPermission.whileInUse);
      }
    }
    
    if (mounted) {
      setState(() {
        _deviceSupport = support;
        _locationError = !locationEnabled;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Qibla Compass'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_checking)
              const TasbehLoader(size: 100)
            else if (!_deviceSupport)
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.sensors_off_rounded,
                        color: AppColors.gold, size: 40),
                    const SizedBox(height: 12),
                    Text('Compass sensor not available on this device.',
                        style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              )
            else if (_locationError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('sahi direction dekhny k ly hmy location on krni hu gi.',
                          style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _checking = true);
                          _checkSupport();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Check Again'),
                      )
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<QiblahDirection>(
                stream: FlutterQiblah.qiblahStream,
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) {
                    return const TasbehLoader(size: 100);
                  }
                  final direction = snapshot.data!;

                  // qiblah ≈ 0 when phone top is facing Qibla
                  double normalize(double deg) {
                    var a = deg % 360;
                    if (a < 0) a += 360;
                    return a;
                  }

                  final relativeAngle = normalize(direction.qiblah);
                  final needleRad = relativeAngle * (math.pi / 180);
                  // Shortest turn to Qibla: 0° = facing Qibla, max 180°
                  final degreesOff = relativeAngle > 180
                      ? 360 - relativeAngle
                      : relativeAngle;
                  final isAligned = degreesOff < 5.0;
                  final needleColor =
                      isAligned ? AppColors.success : AppColors.gold;

                  return Column(
                    children: [
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Fixed Kaaba background — does not rotate
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: needleColor.withValues(alpha: 0.5),
                                  width: isAligned ? 3 : 2,
                                ),
                                gradient: const RadialGradient(
                                  colors: [
                                    AppColors.card,
                                    AppColors.backgroundDark,
                                  ],
                                ),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/kaaba.png'),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black54,
                                    BlendMode.darken,
                                  ),
                                ),
                              ),
                            ),
                            // Needle only rotates toward Qibla
                            Transform.rotate(
                              angle: needleRad,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mosque_rounded,
                                    color: needleColor,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 8,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: needleColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                      boxShadow: isAligned
                                          ? [
                                              BoxShadow(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.55),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.4),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Center pivot
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: needleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.backgroundDark,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${degreesOff.toStringAsFixed(0)}°',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: needleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAligned
                            ? 'Facing Qibla!'
                            : 'Qibla se angle',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isAligned
                              ? AppColors.success
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_rounded,
                                color: needleColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAligned
                                    ? 'Perfect! Aap Qibla ki taraf face kar rahe hain.'
                                    : 'Phone ghumaein jab tak needle upar Kaaba ki taraf na aa jaye.',
                                style: AppTextStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
