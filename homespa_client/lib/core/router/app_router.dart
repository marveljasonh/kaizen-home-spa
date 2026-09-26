import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../features/profile/presentation/pages/add_address_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/my_addresses_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/promo/presentation/pages/promo_page.dart';
import '../../features/treatments/domain/entities/treatment.dart';
import '../../features/treatments/domain/entities/treatment_duration.dart';
import '../../features/treatments/presentation/pages/addon_selection_page.dart';
import '../../features/treatments/presentation/pages/treatment_detail_page.dart';
import '../../features/treatments/presentation/pages/treatments_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
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
        builder: (context, state) => const AddAddressPage(),
      ),

      // ── Booking detail ────────────────────────────────────────────────────
      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) => BookingDetailPage(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // ── Treatment detail (full-screen, no bottom nav) ─────────────────────
      GoRoute(
        path: '/treatments/:id',
        builder: (context, state) => TreatmentDetailPage(
          treatmentId: state.pathParameters['id']!,
        ),
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
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
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
                builder: (context, state) => const BookingsPage(),
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
    final unclaimedCount = ref.watch(unusedVouchersProvider).maybeWhen(
          data: (n) => n,
          orElse: () => 0,
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.spa_outlined),
              selectedIcon: Icon(Icons.spa_rounded),
              label: 'Treatments',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unclaimedCount > 0,
                label: Text('$unclaimedCount'),
                backgroundColor: const Color(0xFFD32F2F),
                child: const Icon(Icons.local_offer_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unclaimedCount > 0,
                label: Text('$unclaimedCount'),
                backgroundColor: const Color(0xFFD32F2F),
                child: const Icon(Icons.local_offer_rounded),
              ),
              label: 'Promo',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Router notifier ───────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
