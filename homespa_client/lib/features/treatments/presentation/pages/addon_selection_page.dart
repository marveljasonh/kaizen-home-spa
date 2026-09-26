import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../booking/presentation/providers/booking_cart.dart';
import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_duration.dart';
import '../providers/treatments_providers.dart';

class AddonSelectionPage extends ConsumerStatefulWidget {
  final Treatment treatment;
  final TreatmentDuration? selectedDuration;

  const AddonSelectionPage({
    super.key,
    required this.treatment,
    this.selectedDuration,
  });

  @override
  ConsumerState<AddonSelectionPage> createState() => _AddonSelectionPageState();
}

class _AddonSelectionPageState extends ConsumerState<AddonSelectionPage> {
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  double get _basePrice =>
      widget.selectedDuration?.price ?? widget.treatment.displayPrice;

  double _addonsSubtotal(List<Addon> addons) => addons.fold(0.0, (sum, a) {
        final qty = _quantities[a.id] ?? 0;
        return sum + a.price * qty;
      });

  List<AddonSelection> _buildSelections(List<Addon> addons) => addons
      .where((a) => (_quantities[a.id] ?? 0) > 0)
      .map((a) => AddonSelection(addon: a, quantity: _quantities[a.id]!))
      .toList();

  void _confirm(List<Addon> addons) {
    ref.read(bookingCartProvider.notifier).addItem(
          widget.treatment,
          widget.selectedDuration,
          _buildSelections(addons),
        );
    _showConfirmationAndLeave();
  }

  void _skip() {
    ref.read(bookingCartProvider.notifier).addItem(
          widget.treatment,
          widget.selectedDuration,
        );
    _showConfirmationAndLeave();
  }

  void _showConfirmationAndLeave() {
    // Capture router and messenger before pop — both become invalid after
    // the widget is disposed.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.treatment.name} added to cart'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => router.push('/booking/cart'),
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final addonsAsync = ref.watch(addonsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add-Ons (Optional)'),
      ),
      body: addonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildBody(context, [], text),
        data: (addons) => _buildBody(context, addons, text),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Addon> addons,
    TextTheme text,
  ) {
    final addonsSubtotal = _addonsSubtotal(addons);
    final total = _basePrice + addonsSubtotal;

    return Column(
      children: [
        // ── Treatment context strip ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: AppColors.surface,
          child: Row(
            children: [
              Icon(Icons.spa_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.treatment.name,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatRupiah(_basePrice),
                style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        ),

        // ── Add-on list ──────────────────────────────────────────────────────
        Expanded(
          child: addons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No add-ons available',
                        style: text.bodyLarge
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Skip" to add the treatment without add-ons.',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  itemCount: addons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _AddonCard(
                    addon: addons[i],
                    quantity: _quantities[addons[i].id] ?? 0,
                    onIncrement: () => setState(
                        () => _quantities[addons[i].id] =
                            (_quantities[addons[i].id] ?? 0) + 1),
                    onDecrement: () {
                      final current = _quantities[addons[i].id] ?? 0;
                      if (current > 0) {
                        setState(() => _quantities[addons[i].id] = current - 1);
                      }
                    },
                  ),
                ),
        ),

        // ── Bottom action bar ────────────────────────────────────────────────
        _BottomBar(
          total: total,
          addonsSubtotal: addonsSubtotal,
          onSkip: _skip,
          onAddToCart: () => _confirm(addons),
        ),
      ],
    );
  }
}

// ── Add-on card ────────────────────────────────────────────────────────────────

class _AddonCard extends StatelessWidget {
  final Addon addon;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _AddonCard({
    required this.addon,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isSelected = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.45)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon.name,
                    style: text.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (addon.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(addon.description,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text(
                  formatRupiah(addon.price),
                  style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QuantityControl(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            text: text,
          ),
        ],
      ),
    );
  }
}

// ── Quantity +/- control ───────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final TextTheme text;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return FilledButton.tonal(
        onPressed: onIncrement,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: const Icon(Icons.add_rounded, size: 20),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: Icons.remove_rounded,
          onTap: onDecrement,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        _CircleButton(
          icon: Icons.add_rounded,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double total;
  final double addonsSubtotal;
  final VoidCallback onSkip;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.total,
    required this.addonsSubtotal,
    required this.onSkip,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: text.titleSmall),
                Row(
                  children: [
                    if (addonsSubtotal > 0) ...[
                      Text(
                        '+${formatRupiah(addonsSubtotal)} add-ons  ',
                        style: text.labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    Text(
                      formatRupiah(total),
                      style: AppTypography.headingMedium.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onAddToCart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
