import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'reviews_provider.dart';

class AllReviewsPage extends ConsumerWidget {
  const AllReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: reviewsAsync.maybeWhen(
          data: (reviews) => Text('Reviews (${reviews.length})'),
          orElse: () => const Text('Reviews'),
        ),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text(
            'Could not load reviews',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline_rounded,
                      size: 56, color: AppColors.accent.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          final avg =
              reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _buildSummaryRow(avg, reviews.length);
              return _ReviewCard(review: reviews[i - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(double avg, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                i < avg.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFC9A96E),
                size: 18,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            avg.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count ${count == 1 ? 'review' : 'reviews'})',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final TherapistReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars = review.rating.round().clamp(1, 5);
    final month = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][review.createdAt.month];
    final dateStr =
        '$month ${review.createdAt.day}, ${review.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFC9A96E),
                size: 16,
              );
            }),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
