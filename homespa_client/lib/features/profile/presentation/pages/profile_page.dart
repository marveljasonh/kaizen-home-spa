import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/app_preferences_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../promo/presentation/providers/rewards_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final text = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    final totalPointsAsync = ref.watch(clientTotalPointsProvider);
    final totalPoints = totalPointsAsync.maybeWhen(
      data: (v) => v,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(clientTotalPointsProvider);
          ref.invalidate(authNotifierProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text(
              'Profile',
              style: AppTypography.headingMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: false,
          ),

          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, text: text),
          ),

          // ── My Account ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('My Account'),
          ),
          SliverToBoxAdapter(
            child: _Card(
              children: [
                _Item(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.location_on_outlined,
                  label: 'My Addresses',
                  onTap: () => context.push('/profile/addresses'),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.calendar_month_outlined,
                  label: 'Order History',
                  onTap: () => context.go('/bookings'),
                ),
              ],
            ),
          ),

          // ── Preferences ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('Preferences'),
          ),
          SliverToBoxAdapter(
            child: _Card(
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    tileColor: Colors.transparent,
                    secondary: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text('Dark Mode',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).state =
                          val ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
                const _Divider(),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.language_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text('Language',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          language == 'en' ? 'English' : 'Bahasa Indonesia',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                    onTap: () => _showLanguageSheet(context, ref),
                  ),
                ),
                const _Divider(),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    tileColor: Colors.transparent,
                    secondary: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        notificationsEnabled
                            ? Icons.notifications_rounded
                            : Icons.notifications_off_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text('Notifications',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    subtitle: Text('Booking reminders & promotions',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    value: notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    onChanged: (val) {
                      ref.read(notificationsEnabledProvider.notifier).state =
                          val;
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Point & Rewards ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('Point & Rewards'),
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => context.go('/promo'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.stars_rounded,
                          color: AppColors.goldDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Point & Rewards',
                              style: AppTypography.labelLarge),
                          Text(
                            '$totalPoints pts available',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),

          // ── Support ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('Support'),
          ),
          SliverToBoxAdapter(
            child: _Card(
              children: [
                _Item(
                  icon: Icons.help_outline_rounded,
                  label: 'Help Center',
                  onTap: () => _showFaqSheet(context),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Contact Us',
                  onTap: () =>
                      _launchUrl('https://wa.me/6281234567890'),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _showTextSheet(
                      context, 'Privacy Policy', _kPrivacyText),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  onTap: () => _showTextSheet(
                      context, 'Terms & Conditions', _kTermsText),
                ),
                const _Divider(),
                _Item(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate the App',
                  onTap: () => _launchUrl(
                      'https://play.google.com/store/apps/details?id=com.homespa.client'),
                ),
              ],
            ),
          ),

          // ── Danger zone ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('Account'),
          ),
          SliverToBoxAdapter(
            child: _Card(
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Color(0xFFD32F2F), size: 18),
                    ),
                    title: Text(
                      'Log Out',
                      style: AppTypography.bodyMedium
                          .copyWith(color: const Color(0xFFD32F2F)),
                    ),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ),
                const _Divider(),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.delete_forever_rounded,
                          color: Color(0xFFD32F2F), size: 18),
                    ),
                    title: Text(
                      'Delete Account',
                      style: AppTypography.bodyMedium
                          .copyWith(color: const Color(0xFFD32F2F)),
                    ),
                    onTap: () => _showDeleteDialog(context, ref),
                  ),
                ),
              ],
            ),
          ),

          // ── Version footer ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.spa_outlined,
                        color: AppColors.gold, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      'Kaizen Home Spa v1.0.0',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showLanguageSheet(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(builder: (ctx, r, _) {
        final lang = r.watch(languageProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text('Select Language',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              _LangTile(
                label: 'English',
                code: 'en',
                selected: lang == 'en',
                onTap: () {
                  r.read(languageProvider.notifier).state = 'en';
                  Navigator.of(ctx).pop();
                },
              ),
              _LangTile(
                label: 'Bahasa Indonesia',
                code: 'id',
                selected: lang == 'id',
                onTap: () {
                  r.read(languageProvider.notifier).state = 'id';
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  void _showFaqSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const _SheetHandle(),
            const SizedBox(height: 12),
            Text('Help Center',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const _FaqItem(
              q: 'How do I book a session?',
              a: 'Go to Treatments, select your preferred treatment, choose a duration and any add-ons, then proceed through the booking flow to confirm.',
            ),
            const _FaqItem(
              q: 'Can I choose my therapist?',
              a: 'Yes! During booking you can select from available therapists or choose "Any Available" for flexibility.',
            ),
            const _FaqItem(
              q: 'How do I cancel a booking?',
              a: 'Cancellations can be made up to 2 hours before your scheduled session. Contact our support team via WhatsApp for assistance.',
            ),
            const _FaqItem(
              q: 'What payment methods are accepted?',
              a: 'Currently we accept Cash on Delivery (COD). The therapist will collect payment upon arrival at your location.',
            ),
            const _FaqItem(
              q: 'How do I use a promo code?',
              a: 'Go to the Promo tab, enter your promo code in the "Enter Promo Code" field and tap Apply. The discount will carry over to your next booking.',
            ),
            const _FaqItem(
              q: 'How does loyalty work?',
              a: 'Complete 10 bookings to unlock rewards. Your progress is tracked automatically in the Profile tab.',
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            const _SheetHandle(),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(content,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.7)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child:
                const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(ref: ref),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AppUser user;
  final TextTheme text;

  const _ProfileHeader({
    required this.user,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        _initials(user),
                        style: AppTypography.headingLarge.copyWith(
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name ?? 'User',
            style: AppTypography.headingMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              user.phone!,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Profile',
                    style: AppTypography.labelMedium
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(AppUser user) {
    final name = user.name;
    if (name == null || name.isEmpty) {
      return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
    }
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
  }
}

// ── Delete account dialog ──────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action is permanent. All your bookings, rewards and data will be erased.',
          ),
          const SizedBox(height: 16),
          Text(
            'Type DELETE to confirm:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _matches = v.trim() == 'DELETE'),
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _matches ? const Color(0xFFD32F2F) : null,
          ),
          onPressed: _matches
              ? () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Account deletion requested. Our team will contact you within 24 hours.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                  widget.ref
                      .read(authNotifierProvider.notifier)
                      .signOut();
                }
              : null,
          child: const Text('Delete',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        tileColor: Colors.transparent,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 60,
        endIndent: 16,
        color: AppColors.border,
      );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.15),
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q,
              style:
                  text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(a,
              style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        tileColor: Colors.transparent,
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check_rounded, color: AppColors.primary)
            : null,
        onTap: onTap,
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
We use industry-standard encryption and Supabase's secure infrastructure to protect your data. Access is restricted to authorized personnel only.

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
