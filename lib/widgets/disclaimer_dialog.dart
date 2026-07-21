import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

const String kDisclaimerText =
    'یہ ایپ سیفی ٹی وی کی ملکیت ہے۔ اس کا مرکزی آستانہ عالیہ سے براہ راست کوئی '
    'واسطہ نہیں ہے۔ اس لیے اگر ایپ میں کسی قسم کی کوئی غلطی یا کوتاہی ہو تو اس کا '
    'ذمہ دار سیفی ٹی وی خود ہو گا، مرکزی آستانہ عالیہ فقیر آباد اس کا ذمہ دار نہیں '
    'ہوگا۔ اس ایپ کا مقصد سیفیوں کو ایک ہی جگہ پر سارا مواد دینا ہے۔ تعاون کا شکریہ۔';

/// Shows the first-launch disclaimer dialog.
/// Cannot be dismissed by tapping outside — user MUST tap the button.
Future<void> showDisclaimerDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must press button
    builder: (_) => const _DisclaimerDialog(),
  );
}

class _DisclaimerDialog extends StatelessWidget {
  const _DisclaimerDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D5338), Color(0xFF122A1E)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.25),
                    AppColors.gold.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'اہم اطلاع',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontFamily: 'Amiri',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  kDisclaimerText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.85,
                    fontSize: 15,
                    color: const Color(0xFFE8E8E8),
                    fontFamily: 'Amiri',
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),

            // ── Divider ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: AppColors.gold.withOpacity(0.3), height: 24),
            ),

            // ── Button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.gold.withOpacity(0.4),
                  ),
                  child: Text(
                    'سمجھ گیا',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 16,
                      fontFamily: 'Amiri',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
