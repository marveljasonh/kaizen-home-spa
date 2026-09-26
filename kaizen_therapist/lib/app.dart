import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/supabase_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/orders/presentation/orders_page.dart';
import 'features/orders/presentation/order_detail_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/schedule/presentation/schedule_page.dart';
import 'features/schedule/presentation/schedule_provider.dart';
import 'features/rider/presentation/rider_dashboard_page.dart';
import 'features/rider/presentation/rider_assignment_detail_page.dart';
import 'features/rider/presentation/rider_history_detail_page.dart';

// Notifies GoRouter when auth state or user role changes so redirects re-evaluate.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Stream<dynamic> authStream) {
    notifyListeners();
    _authSub = authStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _authSub;

  void update() => notifyListeners();

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notifier = _RouterNotifier(supabase.auth.onAuthStateChange);

  // Re-evaluate routes whenever the role finishes loading (e.g. on app restart
  // with an existing session, or after login when the FutureProvider resolves).
  ref.listen(userRoleProvider, (_, __) => notifier.update());

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';

      if (!isLoggedIn) return isOnLogin ? null : '/login';

      if (isLoggedIn && isOnLogin) {
        // Stay on login while role is still loading (notifier fires when done).
        final roleAsync = ref.read(userRoleProvider);
        return roleAsync.when(
          data: (role) => role == 'rider' ? '/rider-dashboard' : '/dashboard',
          loading: () => null,
          error: (_, __) => '/dashboard',
        );
      }

      // Guard cross-role navigation
      final role = ref.read(userRoleProvider).value;
      final isTherapistRoute = loc.startsWith('/dashboard') ||
          loc.startsWith('/orders') ||
          loc.startsWith('/schedule') ||
          loc.startsWith('/profile') ||
          loc.startsWith('/order-detail');
      final isRiderRoute = loc.startsWith('/rider');

      if (role == 'rider' && isTherapistRoute) return '/rider-dashboard';
      if (role == 'therapist' && isRiderRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Therapist routes (with bottom nav shell) ──────────────────────
      ShellRoute(
        builder: (context, state, child) => _TherapistShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrdersPage()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SchedulePage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        path: '/order-detail/:id',
        builder: (context, state) =>
            OrderDetailPage(orderId: state.pathParameters['id']!),
      ),

      // ── Rider routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/rider-dashboard',
        builder: (context, state) => const RiderDashboardPage(),
      ),
      GoRoute(
        path: '/rider-assignment/:id',
        builder: (context, state) => RiderAssignmentDetailPage(
          assignmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/rider-history-detail/:id',
        builder: (context, state) => RiderHistoryDetailPage(
          assignmentId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

class _TherapistShell extends ConsumerWidget {
  final Widget child;

  const _TherapistShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final upcomingCount = ref.watch(upcomingCountProvider).value ?? 0;

    int selectedIndex = 0;
    if (location.startsWith('/orders')) selectedIndex = 1;
    if (location.startsWith('/schedule')) selectedIndex = 2;
    if (location.startsWith('/profile')) selectedIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/orders');
            case 2:
              context.go('/schedule');
            case 3:
              context.go('/profile');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: upcomingCount > 0,
              label: Text('$upcomingCount'),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: upcomingCount > 0,
              label: Text('$upcomingCount'),
              child: const Icon(Icons.calendar_month),
            ),
            label: 'Schedule',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class KaizenEmployeeApp extends ConsumerWidget {
  const KaizenEmployeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kaizen Employee',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
