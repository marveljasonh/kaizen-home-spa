import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/promo/presentation/providers/rewards_provider.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/booking/presentation/pages/booking_cart_page.dart';
import '../../features/booking/presentation/pages/booking_detail_page.dart';
import '../../features/booking/presentation/pages/bookings_page.dart';
import '../../features/booking/presentation/pages/location_page.dart';
import '../../features/booking/presentation/pages/payment_page.dart';
import '../../features/booking/presentation/pages/review_confirm_page.dart';
import '../../features/booking/presentation/pages/schedule_page.dart';
import '../../features/booking/presentation/pages/therapist_selection_page.dart';
import '../../features/booking/presentation/pages/voucher_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/intake/presentation/pages/client_intake_page.dart';
import '../../features/intake/presentation/providers/intake_providers.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/profile/domain/entities/saved_address.dart';
import '../../features/profile/presentation/pages/add_address_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/my_addresses_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/promo/presentation/pages/promo_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/treatments/domain/entities/treatment.dart';
import '../../features/treatments/domain/entities/treatment_duration.dart';
import '../../features/treatments/presentation/pages/addon_selection_page.dart';
import '../../features/treatments/presentation/pages/treatment_detail_page.dart';
import '../../features/treatments/presentation/pages/treatments_page.dart';

/// Shown while the router checks client_intake for the signed-in user.
const String _kIntakeCheck = '/intake/check';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');

      if (!isAuthenticated) return isAuthRoute ? null : '/auth/login';

      // A brand-new account sees the welcome screen first; its Get Started
      // clears the flag and opens the intake form. Checked before the intake
      // lookup, so sign-up never passes through Home or the check page.
      if (ref.read(justSignedUpProvider)) {
        return location == '/welcome' || location.startsWith('/intake')
            ? null
            : '/welcome';
      }

      // New clients fill the intake form before entering the app. Wait on
      // the (cached) check on a neutral page, so Home never flashes first.
      // On the intake pages themselves, a refetch after saving must not move
      // the client (the page navigates when the save is done).
      final intake = ref.read(clientIntakeProvider);
      if (intake.isLoading) {
        return location.startsWith('/intake') ? null : _kIntakeCheck;
      }
      // A failed check lets the client in rather than locking them out.
      final needsIntake = intake is AsyncData && intake.value == null;
      if (needsIntake) return location == '/intake' ? null : '/intake';

      if (isAuthRoute ||
          location == _kIntakeCheck ||
          location == '/intake' ||
          location == '/welcome') {
        return '/';
      }
      return null;
    },
    routes: [
      // ── Welcome (right after sign-up; no bottom nav) ─────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),

      // ── Client intake (full-screen, no bottom nav) ───────────────────────
      GoRoute(
        path: _kIntakeCheck,
        builder: (context, state) => const IntakeCheckPage(),
      ),
      GoRoute(
        path: '/intake',
        builder: (context, state) => const ClientIntakePage(),
      ),
      GoRoute(
        path: '/intake/edit',
        builder: (context, state) => const ClientIntakePage(editMode: true),
      ),

      // ── Profile sub-pages (no bottom nav) ────────────────────────────────
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const MyAddressesPage(),
      ),
      GoRoute(
        path: '/profile/addresses/add',
        // `extra`: the SavedAddress to edit; none adds a new one.
        builder: (context, state) =>
            AddAddressPage(address: state.extra as SavedAddress?),
      ),

      // ── Booking detail ────────────────────────────────────────────────────
      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) =>
            BookingDetailPage(bookingId: state.pathParameters['id']!),
      ),

      // ── Treatment detail (full-screen, no bottom nav) ─────────────────────
      // ── Treatment search (Home hero → Search) ─────────────────────────────
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      GoRoute(
        path: '/treatments/:id',
        builder: (context, state) =>
            TreatmentDetailPage(treatmentId: state.pathParameters['id']!),
      ),

      // ── Add-on selection (pushed from treatment detail) ───────────────────
      GoRoute(
        path: '/treatments/:id/addons',
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return AddonSelectionPage(
            treatment: extra['treatment'] as Treatment,
            selectedDuration: extra['duration'] as TreatmentDuration?,
          );
        },
      ),

      // ── Booking flow (no bottom nav) ──────────────────────────────────────
      GoRoute(
        path: '/booking/cart',
        builder: (context, state) => const BookingCartPage(),
      ),
      GoRoute(
        path: '/booking/therapist',
        builder: (context, state) => const TherapistSelectionPage(),
      ),
      GoRoute(
        path: '/booking/schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(
        path: '/booking/location',
        builder: (context, state) => const LocationPage(),
      ),
      GoRoute(
        path: '/booking/voucher',
        builder: (context, state) => const VoucherPage(),
      ),
      GoRoute(
        path: '/booking/review',
        builder: (context, state) => const ReviewConfirmPage(),
      ),
      GoRoute(
        path: '/booking/payment',
        builder: (context, state) => const PaymentPage(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpPage(),
      ),

      // ── Main app shell with bottom navigation ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/treatments',
                builder: (context, state) => const TreatmentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                // `?tab=past` opens the Past tab (Home → "View All").
                builder: (context, state) => BookingsPage(
                  initialTab: BookingsTab.fromQuery(state.uri.queryParameters),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/promo',
                builder: (context, state) => const PromoPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── App shell ─────────────────────────────────────────────────────────────────

class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unclaimedCount = ref
        .watch(unusedVouchersProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.darkOlive,
      body: navigationShell,
      bottomNavigationBar: _KaizenNavBar(
        currentIndex: navigationShell.currentIndex,
        giftBadgeCount: unclaimedCount,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ── Bottom nav bar (Figma: kaizen › Home › navbar) ────────────────────────────

/// Icon order matches the shell branches: Home, Treatments, Bookings, Promo,
/// Profile.
const List<String> _kNavIcons = [
  'assets/icons/nav_home_24.svg',
  'assets/icons/nav_cart_24.svg',
  'assets/icons/nav_calendar_24.svg',
  'assets/icons/nav_gift_24.svg',
  'assets/icons/nav_user_24.svg',
];
const int _kGiftIndex = 3;

const Color _kNavActive = Colors.white;
const Color _kNavInactive = Color(0xFFB2B2B2);
const double _kNavIconSize = 24.326;
const double _kNavHitPad = 12; // enlarges tap target without moving icons
const double _kNavContentHeight = 56;

class _KaizenNavBar extends StatelessWidget {
  final int currentIndex;
  final int giftBadgeCount;
  final ValueChanged<int> onTap;

  const _KaizenNavBar({
    required this.currentIndex,
    required this.giftBadgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 56 of content (icons centred) + the home-indicator area, trimmed by 8
    // on iPhone (34 → 26) and 14 where there is none — was 63 + 34 = 97.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomArea = bottomInset > 0
        ? (bottomInset - 8).clamp(12.0, double.infinity)
        : 14.0;

    return Container(
      height: _kNavContentHeight + bottomArea,
      color: AppColors.navBarDark,
      // First icon left 34.2, last right 35.0 (402 frame).
      padding: EdgeInsets.only(
        left: 34.2 - _kNavHitPad,
        right: 35.0 - _kNavHitPad,
        bottom: bottomArea,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _kNavIcons.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.all(_kNavHitPad),
                child: _navIcon(i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navIcon(int i) {
    final icon = SvgPicture.asset(
      _kNavIcons[i],
      width: _kNavIconSize,
      height: _kNavIconSize,
      colorFilter: ColorFilter.mode(
        i == currentIndex ? _kNavActive : _kNavInactive,
        BlendMode.srcIn,
      ),
    );
    if (i != _kGiftIndex) return icon;
    return Badge(
      isLabelVisible: giftBadgeCount > 0,
      label: Text('$giftBadgeCount'),
      backgroundColor: const Color(0xFFD32F2F),
      child: icon,
    );
  }
}

// ── Router notifier ───────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
    // Re-run redirects once the intake check resolves or is refetched.
    ref.listen(clientIntakeProvider, (_, __) => notifyListeners());
  }
}
