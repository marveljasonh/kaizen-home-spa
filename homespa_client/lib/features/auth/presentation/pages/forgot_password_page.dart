import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../../core/i18n/material_i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kaizen_widgets.dart';
import '../widgets/auth_text_field.dart';

/// Forgot-password screen — UI only.
///
/// The visual flow is complete (enter email → "Send Reset Link" → success
/// state with a resend countdown). Sending the actual reset email is left to
/// the backend: implement [_requestPasswordReset] below.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _resendSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  // ── Backend hook ────────────────────────────────────────────────────────────

  /// TODO(backend): send the password-reset email for [email].
  ///
  /// Throw an exception (its message is shown under the field) if the request
  /// fails. Until this is implemented the screen only simulates a short delay
  /// and then shows the success state.
  Future<void> _requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent again')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _backToLogin,
                  tooltip: tr('Back'),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _sent ? _buildSuccess() : _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _IconBadge(icon: Icons.lock_reset_rounded),
        const SizedBox(height: 24),
        Text(
          'Forgot password?',
          textAlign: TextAlign.center,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter the email linked to your account and we'll send you a link to reset your password.",
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return tr('Email is required');
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
              if (!ok) return tr('Enter a valid email');
              return null;
            },
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 24),
        KaizenPrimaryButton(
          label: 'Send Reset Link',
          onTap: _isLoading ? null : _submit,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _backToLogin,
              child: Text(
                'Sign In',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuccess() {
    final email = _emailController.text.trim();
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _IconBadge(icon: Icons.mark_email_read_outlined),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a password reset link to",
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Can't find it? Check your spam folder.",
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        KaizenPrimaryButton(label: 'Back to Sign In', onTap: _backToLogin),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _secondsLeft > 0 || _isLoading ? null : _resend,
            child: Text(
              _secondsLeft > 0 ? 'Resend link in ${_secondsLeft}s' : 'Resend link',
              style: AppTypography.labelMedium.copyWith(
                color: _secondsLeft > 0
                    ? AppColors.textMuted
                    : AppColors.primary,
              ),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _sent = false;
              _timer?.cancel();
              _secondsLeft = 0;
            }),
            child: Text(
              'Use a different email',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: AppColors.primary),
      ),
    );
  }
}
