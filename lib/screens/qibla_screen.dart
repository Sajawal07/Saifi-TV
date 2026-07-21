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
                  
                  // direction.direction = current device heading (degrees from North)
                  // direction.qiblah   = absolute Qibla bearing (degrees from North)
                  // To show compass: rotate the compass face by -heading so North stays up
                  // Then place the Qibla marker at qiblah angle from top
                  final double headingRad = -(direction.direction * (math.pi / 180));
                  final double qiblahAngleDiff = direction.qiblah - direction.direction;
                  bool isAligned = (qiblahAngleDiff.abs() % 360) < 3.0 || 
                                   (qiblahAngleDiff.abs() % 360) > 357.0;

                  return Column(
                    children: [
                      // Compass
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Compass ring rotates with device heading
                            Transform.rotate(
                              angle: headingRad,
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  gradient: const RadialGradient(
                                    colors: [AppColors.card, AppColors.backgroundDark],
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
                            ),
                            // Needle: fixed, always pointing to Qibla (top = Qibla direction)
                            // We rotate needle by the qiblah bearing relative to North
                            Transform.rotate(
                              angle: direction.qiblah * (math.pi / 180),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: isAligned
                                          ? const LinearGradient(colors: [Colors.greenAccent, Colors.green])
                                          : AppColors.goldGradient,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted.withValues(alpha: 0.4),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Center dot
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                gradient: AppColors.goldGradient,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Kaaba icon at top of needle
                            Positioned(
                              top: 16,
                              child: Transform.rotate(
                                angle: direction.qiblah * (math.pi / 180),
                                child: const Icon(Icons.mosque_rounded,
                                    color: AppColors.gold, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${direction.qiblah.toStringAsFixed(1)}°',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isAligned ? Colors.greenAccent : AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAligned ? '✅ Facing Qibla!' : 'Qibla Bearing from North',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isAligned ? Colors.greenAccent : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.explore_rounded,
                                color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rotate your phone until the golden arrow points upward toward the Kaaba icon.',
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
