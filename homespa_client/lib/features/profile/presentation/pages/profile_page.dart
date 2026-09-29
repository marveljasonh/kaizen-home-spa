import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/app_preferences_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/widgets/kaizen_page.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../promo/presentation/providers/promo_providers.dart';
import '../../../promo/presentation/providers/rewards_provider.dart';

// Profile (Account tab): Promos hero with the avatar row (avatar, name,
// email); below it the points glass card, then glass menu cards.

/// Avatar row under the title: 64 avatar beside name and email.
const double _kAvatarSize = 64;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final pointsAsync = ref.watch(clientTotalPointsProvider);

    void openRewards() {
      ref.read(promoTabRequestProvider.notifier).state = 1;
      context.go('/promo');
    }

    return KaizenHeroPage(
      label: 'Account',
      title: 'Profile',
      heroRow: _ProfileHeroRow(user: user),
      heroRowHeight: _kAvatarSize,
      onRefresh: () async {
        ref.invalidate(clientTotalPointsProvider);
        ref.invalidate(authNotifierProvider);
      },
      children: [
        // ── Points ─────────────────────────────────────────────────────────
        KaizenGutter(
          _PointsCard(
            points: pointsAsync.value,
            loading: pointsAsync.isLoading && !pointsAsync.hasValue,
            onTap: openRewards,
          ),
        ),

        // ── My Account ─────────────────────────────────────────────────────
        const KaizenSectionLabel('My Account'),
        KaizenGutter(
          _MenuCard(
            rows: [
              _MenuRow(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _MenuRow(
                icon: Icons.health_and_safety_outlined,
                title: 'Health & Preferences',
                subtitle: 'Your intake form answers',
                onTap: () => context.push('/intake/edit'),
              ),
              _MenuRow(
                icon: Icons.location_on_outlined,
                title: 'My Addresses',
                onTap: () => context.push('/profile/addresses'),
              ),
              _MenuRow(
                icon: Icons.card_giftcard_rounded,
                title: 'Point & Rewards',
                onTap: openRewards,
              ),
              _MenuRow(
                icon: Icons.calendar_month_outlined,
                title: 'Order History',
                onTap: () => context.go('/bookings'),
              ),
              _MenuRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Contact Us',
                subtitle: 'Chat with us on WhatsApp',
                onTap: () => _launchUrl('https://wa.me/6281234567890'),
              ),
            ],
          ),
        ),

        // ── Preferences ────────────────────────────────────────────────────
        const KaizenSectionLabel('Preferences'),
        KaizenGutter(
          _MenuCard(
            rows: [
              _MenuRow(
                icon: themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Dark Mode',
                trailing: _Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) =>
                      ref.read(themeModeProvider.notifier).state = val
                      ? ThemeMode.dark
                      : ThemeMode.light,
                ),
              ),
              _MenuRow(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: language == 'en' ? 'English' : 'Bahasa Indonesia',
                onTap: () => _showLanguageSheet(context),
              ),
              _MenuRow(
                icon: notificationsEnabled
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_off_outlined,
                title: 'Notifications',
                subtitle: 'Booking reminders & promotions',
                trailing: _Switch(
                  value: notificationsEnabled,
                  onChanged: (val) =>
                      ref.read(notificationsEnabledProvider.notifier).state =
                          val,
                ),
              ),
            ],
          ),
        ),

        // ── Support ────────────────────────────────────────────────────────
        const KaizenSectionLabel('Support'),
        KaizenGutter(
          _MenuCard(
            rows: [
              _MenuRow(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () => _showFaqSheet(context),
              ),
              _MenuRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () =>
                    _showTextSheet(context, 'Privacy Policy', _kPrivacyText),
              ),
              _MenuRow(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () =>
                    _showTextSheet(context, 'Terms & Conditions', _kTermsText),
              ),
              _MenuRow(
                icon: Icons.star_outline_rounded,
                title: 'Rate the App',
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.homespa.client',
                ),
              ),
            ],
          ),
        ),

        // ── Account actions ────────────────────────────────────────────────
        const SizedBox(height: kPageCardGap),
        KaizenGutter(
          _MenuCard(
            rows: [
              _MenuRow(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                color: kStatusDanger,
                showChevron: false,
                onTap: () => _confirmLogout(context, ref),
              ),
              _MenuRow(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                color: kStatusDanger,
                showChevron: false,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _DeleteAccountDialog(ref: ref),
                ),
              ),
            ],
          ),
        ),

        // ── Version footer ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              const Icon(Icons.spa_outlined, color: AppColors.gold, size: 20),
              const SizedBox(height: 6),
              Text(
                'Kaizen Home Spa v1.0.0',
                style: flowBody(12, color: kFlowMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showKaizenConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (ok) ref.read(authNotifierProvider.notifier).signOut();
  }

  void _showLanguageSheet(BuildContext context) {
    _showDarkSheet(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, r, _) {
          final lang = r.watch(languageProvider);
          void pick(String code) {
            r.read(languageProvider.notifier).state = code;
            Navigator.of(ctx).pop();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                kPageGutterLeft,
                0,
                kPageGutterRight,
                16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Select Language', style: flowHeading(22, height: 1.2)),
                  const SizedBox(height: 16),
                  KaizenChoiceTabs<String>(
                    options: const [('en', 'English'), ('id', 'Bahasa')],
                    selected: lang,
                    onSelected: pick,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFaqSheet(BuildContext context) {
    _showScrollSheet(
      context,
      title: 'Help Center',
      children: const [
        _FaqItem(
          q: 'How do I book a session?',
          a: 'Go to Treatments, select your preferred treatment, choose a duration and any add-ons, then proceed through the booking flow to confirm.',
        ),
        _FaqItem(
          q: 'Can I choose my therapist?',
          a: 'Yes! During booking you can select from available therapists or choose "Any Available" for flexibility.',
        ),
        _FaqItem(
          q: 'How do I cancel a booking?',
          a: 'Cancellations can be made up to 2 hours before your scheduled session. Contact our support team via WhatsApp for assistance.',
        ),
        _FaqItem(
          q: 'What payment methods are accepted?',
          a: 'Currently we accept Cash on Delivery (COD). The therapist will collect payment upon arrival at your location.',
        ),
        _FaqItem(
          q: 'How do I use a promo code?',
          a: 'Go to the Promo tab, enter your promo code in the "Enter Promo Code" field and tap Apply. The discount will carry over to your next booking.',
        ),
        _FaqItem(
          q: 'How does loyalty work?',
          a: 'Complete 10 bookings to unlock rewards. Your progress is tracked automatically in the Profile tab.',
        ),
      ],
    );
  }

  void _showTextSheet(BuildContext context, String title, String content) {
    _showScrollSheet(
      context,
      title: title,
      children: [
        Text(content, style: flowBody(14, color: kFlowMuted, height: 1.7)),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Sheets ────────────────────────────────────────────────────────────────────

/// #313129 bottom sheet with a handle and the dark flow theme.
Future<void> _showDarkSheet(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: scrollControlled,
    backgroundColor: AppColors.secondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Theme(
      data: flowTheme(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

void _showScrollSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  _showDarkSheet(
    context,
    scrollControlled: true,
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          kPageGutterLeft,
          4,
          kPageGutterRight,
          40,
        ),
        children: [
          Text(title, style: flowHeading(24, height: 1.2)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );
}

// ── Hero avatar row ───────────────────────────────────────────────────────────

class _ProfileHeroRow extends StatelessWidget {
  final AppUser user;
  const _ProfileHeroRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KaizenAvatar(
          url: user.avatarUrl,
          initials: kaizenInitials(user.name, user.email ?? ''),
          size: _kAvatarSize,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.trim().isNotEmpty ? user.name : 'Guest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: flowHeading(22, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                (user.email?.isNotEmpty ?? false) ? user.email! : user.phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: flowBody(12.5, color: kFlowMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Points card ───────────────────────────────────────────────────────────────

/// Promos points balance values (star tile, CalSans 34 number) as a
/// tappable glass card that opens Point & Rewards.
class _PointsCard extends StatelessWidget {
  final int? points;
  final bool loading;
  final VoidCallback onTap;

  const _PointsCard({
    required this.points,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KaizenGlassCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          const KaizenIconTile(Icons.star_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points',
                  style: flowBody(
                    12,
                    weight: FontWeight.w500,
                    color: kFlowMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: loading || points == null
                            ? '—'
                            : NumberFormat.decimalPattern('id').format(points),
                        style: flowHeading(34, height: 1),
                      ),
                      TextSpan(
                        text: '  pts',
                        style: flowBody(14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

// ── Menu ──────────────────────────────────────────────────────────────────────

/// Glass card holding menu rows, separated by hairline dividers.
class _MenuCard extends StatelessWidget {
  final List<_MenuRow> rows;
  const _MenuCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return KaizenGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 16 + 44 + 14,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Icon tile, title (+ optional subtitle), then a chevron or [trailing].
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color = Colors.white,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            KaizenIconTile(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: flowBody(15, weight: FontWeight.w500, color: color),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: flowBody(12, color: kFlowMuted)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron && onTap != null)
              const Icon(Icons.chevron_right_rounded, color: kFlowMuted),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.darkOliveLight,
    activeTrackColor: Colors.white,
    inactiveThumbColor: Colors.white,
    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
    trackOutlineColor: WidgetStatePropertyAll(
      Colors.white.withValues(alpha: 0.3),
    ),
  );
}

// ── Delete account dialog ─────────────────────────────────────────────────────

class _DeleteAccountDialog extends StatefulWidget {
  final WidgetRef ref;
  const _DeleteAccountDialog({required this.ref});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _ctrl = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _delete() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account deletion requested. Our team will contact you within 24 hours.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    widget.ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flowTheme(context),
      child: Dialog(
        backgroundColor: AppColors.secondary, // #313129
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: kPageGutterLeft),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Account', style: flowHeading(24, height: 1.2)),
              const SizedBox(height: 10),
              Text(
                'This action is permanent. All your bookings, rewards and data will be erased.',
                style: flowBody(14, color: kFlowMuted, height: 1.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Type DELETE to confirm:',
                style: flowBody(13, weight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                onChanged: (v) =>
                    setState(() => _matches = v.trim() == 'DELETE'),
                style: flowBody(14),
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: KaizenSmallButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KaizenSmallButton(
                      label: 'Delete',
                      color: _matches ? kStatusDanger : kFlowMuted,
                      onTap: _matches ? _delete : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 14),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: flowBody(14, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(a, style: flowBody(14, color: kFlowMuted, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Static text content ───────────────────────────────────────────────────────

const _kPrivacyText = '''
Kaizen Home Spa ("we", "our", "us") is committed to protecting your personal information.

Information We Collect
We collect your name, email address, phone number, and location when you use our services. We also collect booking history and payment information to facilitate our services.

How We Use Your Information
Your information is used to process bookings, communicate service updates, and improve our platform. We do not sell your personal data to third parties.

Data Security
We use industry-standard encryption and secure cloud infrastructure to protect your data. Access is restricted to authorized personnel only.

Your Rights
You may request access, correction, or deletion of your personal data at any time by contacting us at privacy@kaizenhomaspa.com.

Updates
We may update this policy periodically. Continued use of the app after changes constitutes acceptance of the updated policy.

Last updated: January 2026
''';

const _kTermsText = '''
By using the Kaizen Home Spa application, you agree to the following terms.

Services
Kaizen Home Spa provides at-home spa and wellness services. Bookings are subject to therapist availability and your confirmed location.

Booking & Cancellation
Bookings must be cancelled at least 2 hours before the scheduled time. Late cancellations may incur a fee at our discretion.

Payment
Currently, all payments are made via Cash on Delivery. You agree to have the exact amount ready upon the therapist's arrival.

User Conduct
You agree not to misuse the platform, provide false information, or engage in fraudulent activity.

Liability
Kaizen Home Spa is not liable for indirect or consequential damages arising from the use of our services. Our liability is limited to the amount paid for the specific booking in question.

Governing Law
These terms are governed by the laws of the Republic of Indonesia.

Last updated: January 2026
''';
