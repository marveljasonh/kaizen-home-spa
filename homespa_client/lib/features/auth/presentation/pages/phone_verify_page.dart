import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

class PhoneVerifyPage extends ConsumerStatefulWidget {
  const PhoneVerifyPage({super.key});

  @override
  ConsumerState<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends ConsumerState<PhoneVerifyPage> {
  final _otpController = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAwaitingOtp) return;
    final code = _otpController.text.trim();
    if (code.length != 6) return;

    await ref
        .read(authNotifierProvider.notifier)
        .verifyPhoneOtp(
          phone: authState.phone,
          token: code,
          gender: authState.gender,
        );
  }

  Future<void> _resend() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAwaitingOtp) return;
    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(phone: authState.phone),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not resend: $e')));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final phone = authState is AuthAwaitingOtp ? authState.phone : '';

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthError) {
        _otpController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => ref
                      .read(authNotifierProvider.notifier)
                      .skipPhoneVerification(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Phone',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n$phone',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // OTP input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.headingLarge.copyWith(
                  letterSpacing: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: '- - - - - -',
                  hintStyle: AppTypography.headingMedium.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: (val) {
                  if (val.length == 6) _verify();
                },
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: isLoading ? null : _verify,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isResending ? null : _resend,
                    child: Text(
                      _isResending ? 'Sending…' : 'Resend',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => ref
                    .read(authNotifierProvider.notifier)
                    .skipPhoneVerification(),
                child: Text(
                  'Skip for now',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
