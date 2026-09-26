import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/status_badge.dart';
import 'order_detail_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(orderDetailProvider(orderId));
    final actionState = ref.watch(orderActionProvider(orderId));

    // Auto-navigate back when an external change (e.g. admin) moves the booking
    // to a terminal state. Uses prev/next comparison so it only fires on change.
    ref.listen(orderDetailProvider(orderId), (prev, next) {
      final prevBooking = prev?.valueOrNull;
      final nextBooking = next.valueOrNull;
      if (prevBooking == null || nextBooking == null) return;
      if (prevBooking.status != nextBooking.status && !nextBooking.hasAction) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/orders');
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingAsync.when(
        data: (booking) => _buildContent(context, ref, booking, actionState),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load order details',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    AsyncValue<void> actionState,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(booking),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Client Information',
                  icon: Icons.person_outline,
                  children: [
                    _infoRow('Name', booking.clientName ?? 'Unknown'),
                    _infoRow('Phone', booking.clientPhone ?? 'No phone provided'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: 'Booking Details',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _infoRow('Booking #', booking.bookingNumber),
                    _infoRow(
                      'Scheduled',
                      DateFormat('EEE, dd MMM yyyy\nHH:mm').format(booking.scheduledTime),
                    ),
                    _infoRow('Address', booking.address),
                    if (booking.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _mapsButton(booking.address),
                      const SizedBox(height: 6),
                    ],
                    if (booking.notes != null && booking.notes!.isNotEmpty)
                      _infoRow('Notes', booking.notes!),
                    if (booking.totalPrice != null)
                      _infoRow('Total', booking.totalPriceText),
                  ],
                ),
                const SizedBox(height: 12),
                if (booking.riderName != null && booking.riderName!.isNotEmpty)
                  _buildRiderCard(booking),
                if (booking.riderName != null && booking.riderName!.isNotEmpty)
                  const SizedBox(height: 12),
                if (booking.treatments.isNotEmpty)
                  _buildTreatmentsCard(booking),
                if (booking.addons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAddonsCard(booking),
                ],
                const SizedBox(height: 12),
                _buildPaymentSummary(booking),
                const SizedBox(height: 24),
                if (actionState.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            actionState.error.toString(),
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (booking.hasAction)
                  _buildActionButton(context, ref, booking, actionState),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.bookingNumber,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.clientName ?? 'Client',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                StatusBadge(status: booking.status),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Booking booking) {
    final phone = booking.riderPhone ?? '';
    final waNumber = phone.startsWith('0')
        ? '62${phone.substring(1)}'
        : phone.replaceAll('+', '').replaceAll(' ', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Rider Info',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.riderName!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final uri =
                          Uri.parse('https://wa.me/$waNumber');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'WhatsApp',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapsButton(String address) {
    return GestureDetector(
      onTap: () async {
        final encoded = Uri.encodeComponent(address);
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'Open in Maps',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentsCard(Booking booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.spa_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Treatments',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: booking.treatments.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final t = booking.treatments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (t.durationText.isNotEmpty)
                      Text(
                        t.durationText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (t.priceText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        t.priceText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(Booking booking) {
    final hasDiscount = (booking.discountAmount ?? 0) > 0;
    final total = booking.totalAmountText.isNotEmpty
        ? booking.totalAmountText
        : booking.totalPriceText;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (booking.subtotalText.isNotEmpty)
                  _summaryRow('Subtotal', booking.subtotalText),
                if (hasDiscount)
                  _summaryRow(
                    'Discount',
                    booking.discountText,
                    valueColor: const Color(0xFF27AE60),
                  ),
                if (booking.paymentMethod != null) ...[
                  const SizedBox(height: 4),
                  _summaryRow('Payment', booking.paymentMethodLabel),
                ],
                if (total.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _summaryRow('Total', total, bold: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: bold ? 15 : 13,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsCard(Booking booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Add-ons',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: booking.addons.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final a = booking.addons[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.quantity > 1 ? '${a.name} ×${a.quantity}' : a.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (a.priceText.isNotEmpty)
                      Text(
                        a.priceText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    AsyncValue<void> actionState,
  ) {
    final isLoading = actionState.isLoading;

    return Column(
      children: [
        _ActionProgressIndicator(currentStatus: booking.status),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final success = await ref
                      .read(orderActionProvider(orderId).notifier)
                      .updateStatus(booking.id, booking.nextStatus);

                  if (success && context.mounted) {
                    if (booking.nextStatus == 'completed') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Treatment completed! Great job!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      context.go('/orders');
                    }
                  }
                },
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_getActionIcon(booking.status)),
          label: Text(isLoading ? 'Updating...' : booking.actionButtonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(booking.status),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String status) {
    switch (status) {
      case 'therapist_assigned':
        return Icons.directions_car_outlined;
      case 'on_the_way':
        return Icons.location_on_outlined;
      case 'arrived':
        return Icons.play_circle_outline;
      case 'in_progress':
        return Icons.check_circle_outline;
      default:
        return Icons.arrow_forward;
    }
  }

  Color _getActionColor(String status) {
    switch (status) {
      case 'therapist_assigned':
        return const Color(0xFF3498DB);
      case 'on_the_way':
        return const Color(0xFF9B59B6);
      case 'arrived':
        return const Color(0xFFE67E22);
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
}

class _ActionProgressIndicator extends StatelessWidget {
  final String currentStatus;

  const _ActionProgressIndicator({required this.currentStatus});

  static const _steps = [
    ('Assigned', 'therapist_assigned'),
    ('On the Way', 'on_the_way'),
    ('Arrived', 'arrived'),
    ('In Progress', 'in_progress'),
    ('Done', 'completed'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexWhere((s) => s.$2 == currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                final isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.primary : AppColors.divider,
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex <= currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Center(
                            child: Text(
                              '${stepIndex + 1}',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[stepIndex].$1,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
