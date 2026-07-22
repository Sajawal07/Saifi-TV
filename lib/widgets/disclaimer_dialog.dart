import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

const String kDisclaimerText =
    'یہ ایپ سیفی ٹی وی کی ملکیت ہے۔ اس کا مرکزی آستانہ عالیہ سے براہ راست کوئی '
    'واسطہ نہیں ہے۔ اس لیے اگر ایپ میں کسی قسم کی کوئی غلطی یا کوتاہی ہو تو اس کا '
    'ذمہ دار سیفی ٹی وی خود ہو گا، مرکزی آستانہ عالیہ فقیر آباد اس کا ذمہ دار نہیں '
    'ہوگا۔ اس ایپ کا مقصد سیفیوں کو ایک ہی جگہ پر سارا مواد دینا ہے۔ تعاون کا شکریہ۔';

/// First-launch legal gate: ownership notice + Privacy + YouTube ToS accept.
/// Returns `true` only when the user accepts and continues.
Future<bool> showDisclaimerDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LegalConsentDialog(),
  );
  return result == true;
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _LegalConsentDialog extends StatefulWidget {
  const _LegalConsentDialog();

  @override
  State<_LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<_LegalConsentDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640),
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Terms & Privacy',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.gold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        kDisclaimerText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          height: 1.85,
                          fontSize: 14,
                          color: const Color(0xFFE8E8E8),
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.gold.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text(
                      'YouTube & Privacy',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                        children: [
                          const TextSpan(
                            text:
                                'This app uses YouTube API Services to list and play videos. By continuing you agree to our ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _openUrl(AppUrls.privacyPolicy),
                          ),
                          const TextSpan(text: ', the '),
                          TextSpan(
                            text: 'YouTube Terms of Service',
                            style: const TextStyle(
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _openUrl(AppUrls.youtubeTerms),
                          ),
                          const TextSpan(text: ', and '),
                          TextSpan(
                            text: 'Google Privacy Policy',
                            style: const TextStyle(
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _openUrl(AppUrls.googlePrivacy),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      activeColor: AppColors.gold,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I have read and agree to the Privacy Policy and YouTube Terms of Service.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepted
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor: AppColors.gold.withOpacity(0.25),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
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
