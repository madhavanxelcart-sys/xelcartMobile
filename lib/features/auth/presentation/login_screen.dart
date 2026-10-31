import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../application/auth_controller.dart';
import '../../onboarding/presentation/onboarding_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _sheetOpen = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sheetOpen) return;
    FocusScope.of(context).unfocus();
    final sent = await ref
        .read(authControllerProvider.notifier)
        .sendCode(_phone.text);
    if (!mounted || !sent) return;
    _sheetOpen = true;
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _OtpSheet(),
    );
    _sheetOpen = false;
    if (!mounted) return;
    if (verified == true) {
      ref
          .read(onboardingProvider.notifier)
          .setVerifiedMobile(
            '+91 ${_phone.text.substring(0, 5)} ${_phone.text.substring(5)}',
          );
    }
    ref.read(authControllerProvider.notifier).reset();
    if (verified == true) context.go(RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            AppAssets.xelcartLogo,
                            height: 32,
                            semanticLabel: 'Xelcart',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _SellerBadge(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Less chaos.', style: _headlineStyle),
                  Stack(
                    children: [
                      const Positioned(
                        left: 2,
                        right: 0,
                        bottom: 2,
                        height: 13,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFE8DEFF),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ),
                      const Text('More orders.', style: _headlineStyle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your social orders, all together.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Image.asset(
                      AppAssets.loginHero,
                      height: 220,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Let's get you in",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in with your mobile number.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mobile number',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: TextField(
                      key: const Key('mobileNumber'),
                      controller: _phone,
                      enabled: !auth.isLoading,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onSubmitted: (_) => _sendCode(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'IN +91',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const AppSvgIcon(
                                assetPath: AppAssets.chevronDown,
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColors.border,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We'll send you a code by SMS.",
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (auth.error != null && !_sheetOpen) ...[
                    const SizedBox(height: 8),
                    _ErrorText(auth.error!),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _sendCode,
                      child: auth.isLoading
                          ? const _LoadingIndicator()
                          : const Row(
                              children: [
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    'Send OTP',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                AppSvgIcon(
                                  assetPath: AppAssets.arrowRight,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSvgIcon(
                        assetPath: AppAssets.lockKeyhole,
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'No passwords. Just a one-time code.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.border),
                  Center(
                    child: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Need access?'),
                          content: const Text(
                            'Contact your organization’s administrator to request access to Xelcart.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text(
                        'Need access? Contact your administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _headlineStyle = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.w900,
  height: 1.15,
  color: AppColors.textPrimary,
);

class _SellerBadge extends StatelessWidget {
  const _SellerBadge();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'FOR SOCIAL SELLERS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.accentText,
          ),
        ),
      ),
      Positioned(
        top: -9,
        right: -7,
        child: const CustomPaint(
          size: Size(20, 20),
          painter: _BadgeRaysPainter(),
        ),
      ),
    ],
  );
}

class _BadgeRaysPainter extends CustomPainter {
  const _BadgeRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(4, 9), const Offset(9, 2), paint);
    canvas.drawLine(const Offset(11, 14), const Offset(18, 11), paint);
  }

  @override
  bool shouldRepaint(covariant _BadgeRaysPainter oldDelegate) => false;
}

class _OtpSheet extends ConsumerStatefulWidget {
  const _OtpSheet();

  @override
  ConsumerState<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends ConsumerState<_OtpSheet> {
  final _code = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    _verifying = true;
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyCode(_code.text);
    _verifying = false;
    if (mounted && verified) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final demoCode = ref.watch(authServiceProvider).demoCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verify your number',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code for +91 ${auth.phone ?? ''}.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (demoCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Demo mode: use $demoCode. No SMS is sent.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              key: const Key('otpCode'),
              controller: _code,
              autofocus: true,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                labelText: 'Verification code',
                hintText: '000000',
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 10),
              _ErrorText(auth.error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _verify,
                child: auth.isLoading
                    ? const _LoadingIndicator()
                    : const Text('Verify & continue'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: auth.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Change mobile number'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppColors.dangerText),
    ),
  );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      semanticsLabel: 'Please wait',
    ),
  );
}
