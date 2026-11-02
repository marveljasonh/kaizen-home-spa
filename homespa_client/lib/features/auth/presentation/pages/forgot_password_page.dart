import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/i18n/material_i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kaizen_widgets.dart';
import '../widgets/auth_text_field.dart';

/// Forgot-password screen.
///
/// Phone-based, matching the app's phone+password login: enter phone →
/// a 6-digit code arrives on WhatsApp → enter code + new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _requestCode() async {
    await apiClient.post(
      '/auth/forgot-password',
      body: {'phone': _phoneController.text.trim()},
    );
  }

  Future<void> _submitPhone() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _requestCode();
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
        _errorMessage = tr('Could not send the code. Please try again.');
      });
    }
  }

  Future<void> _submitReset() async {
    if (_isLoading) return;
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.length != 6) {
      setState(() => _errorMessage = tr('Enter the 6-digit code'));
      return;
    }
    if (password.length < 8) {
      setState(
        () => _errorMessage = tr('Password must be at least 8 characters'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await apiClient.post(
        '/auth/reset-password',
        body: {
          'phone': _phoneController.text.trim(),
          'code': code,
          'newPassword': password,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Password updated — sign in with your new password')),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/auth/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.statusCode == 401
            ? tr('Invalid or expired code')
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = tr('Something went wrong. Please try again.');
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
      await _requestCode();
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startCountdown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Code sent again')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not send the code. Please try again.'))),
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
                child: _sent ? _buildResetForm() : _buildPhoneForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone'),
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
          "Enter the phone number linked to your account and we'll send a reset code to your WhatsApp.",
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
            controller: _phoneController,
            label: 'Phone Number',
            hint: '0812 3456 7890',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitPhone(),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return tr('Phone number is required');
              if (value.replaceAll(RegExp(r'\D'), '').length < 8) {
                return tr('Enter a valid phone number');
              }
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
          label: 'Send Code via WhatsApp',
          onTap: _isLoading ? null : _submitPhone,
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

  Widget _buildResetForm() {
    final phone = _phoneController.text.trim();
    return Column(
      key: const ValueKey('reset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _IconBadge(icon: Icons.sms_outlined),
        const SizedBox(height: 24),
        Text(
          'Check your WhatsApp',
          textAlign: TextAlign.center,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'If an account exists for',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          phone,
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'a 6-digit code was sent to its WhatsApp. Enter it with your new password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        AuthTextField(
          controller: _codeController,
          label: 'Reset code',
          hint: '123456',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordController,
          label: 'New password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitReset(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textMuted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 24),
        KaizenPrimaryButton(
          label: 'Reset Password',
          onTap: _isLoading ? null : _submitReset,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _secondsLeft > 0 || _isLoading ? null : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'Resend code in ${_secondsLeft}s'
                  : 'Resend code',
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
              _errorMessage = null;
              _timer?.cancel();
              _secondsLeft = 0;
            }),
            child: Text(
              'Use a different phone number',
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
