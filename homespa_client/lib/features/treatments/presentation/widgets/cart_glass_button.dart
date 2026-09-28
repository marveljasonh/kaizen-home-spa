import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../booking/presentation/providers/booking_cart.dart';
import 'glass_icon_button.dart';

/// Glass cart button with the live booking-cart count as its badge.
class CartGlassButton extends ConsumerWidget {
  const CartGlassButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(bookingCartProvider).itemCount;
    return GlassIconButton(
      svgAsset: 'assets/icons/cart_22.svg',
      iconSize: 22,
      iconOffset: const Offset(12.5, 14.5),
      badgeCount: count,
      onTap: () => context.push('/booking/cart'),
    );
  }
}
