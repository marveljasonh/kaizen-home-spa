import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../models/booking.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final double? clientRating;
  final String? clientReviewText;

  const OrderCard({
    super.key,
    required this.booking,
    this.onTap,
    this.clientRating,
    this.clientReviewText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.bookingNumber,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.clientName ?? 'Unknown Client',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: booking.status),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final isHistory =
        booking.status == 'completed' || booking.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.schedule_outlined,
            DateFormat('EEE, dd MMM yyyy • HH:mm')
                .format(booking.scheduledTime),
          ),
          if (booking.totalPrice != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.payments_outlined,
              booking.totalPriceText,
            ),
          ],
          if (isHistory) ...[
            const SizedBox(height: 8),
            _buildRatingRow(),
          ],
          if (booking.hasAction) ...[
            const SizedBox(height: 12),
            _buildActionChip(),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    if (clientRating == null) {
      return Row(
        children: [
          const Icon(Icons.star_outline_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Awaiting review',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final stars = clientRating!.round().clamp(1, 5);
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (i) => Icon(
              i < stars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: const Color(0xFFF39C12),
              size: 15,
            ),
          ),
        ),
        if (clientReviewText != null && clientReviewText!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              clientReviewText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            booking.actionButtonLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
