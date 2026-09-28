import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/flow_widgets.dart';
import '../../../booking/presentation/providers/booking_cart.dart';
import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_duration.dart';
import '../providers/treatments_providers.dart';

// Add-ons on the booking-flow shell (FlowScaffold): glass cards matching the
// Cart page's summary panel (white 10% fill, hairline white border, no blur),
// olive +/- steppers, and a total + Skip / Add to Cart bar.

final Color _kCardFill = Colors.white.withValues(alpha: 0.10);
final Color _kCardBorder = Colors.white.withValues(alpha: 0.15);
const Color _kSelectedFill = kFlowCardColor; // #4E523B
final Color _kSelectedBorder = Colors.white.withValues(alpha: 0.45);
const Color _kOlive = kFlowAccent; // #5B6240
const double _kCardRadius = 16;

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
    ref
        .read(bookingCartProvider.notifier)
        .addItem(
          widget.treatment,
          widget.selectedDuration,
          _buildSelections(addons),
        );
    _showConfirmationAndLeave();
  }

  void _skip() {
    ref
        .read(bookingCartProvider.notifier)
        .addItem(widget.treatment, widget.selectedDuration);
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

    return FlowScaffold(
      subtitle: 'Optional',
      title: 'Add-Ons',
      body: addonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildBody(context, []),
        data: (addons) => _buildBody(context, addons),
      ),
      bottomBar: addonsAsync.when(
        loading: () => null,
        error: (_, _) => _buildBottomBar([]),
        data: _buildBottomBar,
      ),
    );
  }

  Widget _buildBottomBar(List<Addon> addons) {
    final addonsSubtotal = _addonsSubtotal(addons);
    return _BottomBar(
      total: _basePrice + addonsSubtotal,
      addonsSubtotal: addonsSubtotal,
      onSkip: _skip,
      onAddToCart: () => _confirm(addons),
    );
  }

  Widget _buildBody(BuildContext context, List<Addon> addons) {
    return Column(
      children: [
        // ── Treatment context strip ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(kFlowGutter, 20, kFlowGutter, 0),
          child: _SolidCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.spa_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.treatment.name,
                    style: flowHeading(16, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatRupiah(_basePrice),
                  style: flowBody(
                    14,
                    weight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Add-on list ──────────────────────────────────────────────────────
        Expanded(
          child: addons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kFlowGutter,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 48,
                          color: kFlowMuted,
                        ),
                        const SizedBox(height: 12),
                        Text('No add-ons available', style: flowHeading(18)),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Skip" to add the treatment without add-ons.',
                          style: flowBody(13, color: kFlowMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    kFlowGutter,
                    20,
                    kFlowGutter,
                    8,
                  ),
                  itemCount: addons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _AddonCard(
                    addon: addons[i],
                    quantity: _quantities[addons[i].id] ?? 0,
                    onIncrement: () => setState(
                      () => _quantities[addons[i].id] =
                          (_quantities[addons[i].id] ?? 0) + 1,
                    ),
                    onDecrement: () {
                      final current = _quantities[addons[i].id] ?? 0;
                      if (current > 0) {
                        setState(() => _quantities[addons[i].id] = current - 1);
                      }
                    },
                  ),
                ),
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
    return _SolidCard(
      selected: quantity > 0,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              size: 22,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: flowHeading(17, color: Colors.white),
                ),
                if (addon.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    addon.description,
                    style: flowBody(
                      12,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  formatRupiah(addon.price),
                  style: flowBody(
                    15,
                    weight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QuantityControl(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
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

  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return _CircleButton(icon: Icons.add_rounded, onTap: onIncrement);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: flowBody(
              15,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        _CircleButton(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

/// Glass card: white 10% fill, 1px white 15% border, radius 16. Selected
/// cards get an olive (#4E523B) fill and a brighter 1.5px white border.
class _SolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  const _SolidCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    padding: padding,
    decoration: BoxDecoration(
      color: selected ? _kSelectedFill : _kCardFill,
      borderRadius: BorderRadius.circular(_kCardRadius),
      border: Border.all(
        color: selected ? _kSelectedBorder : _kCardBorder,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: child,
  );
}

/// Solid olive circle with a white icon and hairline white rim.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: _kOlive,
    shape: CircleBorder(
      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
    ),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox.square(
        dimension: 34,
        child: Icon(icon, size: 18, color: Colors.white),
      ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Total', style: flowHeading(22))),
            if (addonsSubtotal > 0)
              Text(
                '+${formatRupiah(addonsSubtotal)} add-ons  ',
                style: flowBody(12, color: kFlowMuted),
              ),
            Text(
              formatRupiah(total),
              style: flowBody(20, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FlowSecondaryButton(label: 'Skip', onTap: onSkip),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FlowPrimaryButton(
                label: 'Add to Cart',
                onTap: onAddToCart,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
