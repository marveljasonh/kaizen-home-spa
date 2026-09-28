import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Booking progress for the dark #313129 flow header: white segments for
/// done/current steps, white 20% for the rest, and "Step N of M".
class BookingStepIndicator extends StatelessWidget
    implements PreferredSizeWidget {
  final int currentStep; // 1-indexed
  final int totalSteps;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
  });

  @override
  Size get preferredSize => const Size.fromHeight(24);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (i) {
            final filled = i < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 5 : 0),
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
