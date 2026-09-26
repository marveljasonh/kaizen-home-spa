import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/time_slot.dart';
import '../providers/booking_cart.dart';
import '../widgets/booking_step_indicator.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final DateTime _today = WIB.now();
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cart = ref.watch(bookingCartProvider);
    final therapistId = cart.therapist?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Date & Time'),
        bottom: const BookingStepIndicator(currentStep: 3),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Today banner ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM y').format(_today),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bookings are available for today only',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Available Times header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Available Times',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),

            // ── Legend ────────────────────────────────────────────────────────
            if (therapistId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _LegendDot(color: const Color(0xFFF5F0E8)),
                    const SizedBox(width: 4),
                    Text('Past',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 14),
                    _LegendDot(color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('Booked',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 14),
                    _LegendDot(color: const Color(0xFF4E523B)),
                    const SizedBox(width: 4),
                    Text('Available',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Slot picker ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TimeSlotPicker(
                therapistId: therapistId,
                selectedDate: _today,
                selectedTime: _selectedTime,
                onTimeSelected: (t) => setState(() => _selectedTime = t),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            onPressed: _selectedTime != null ? _onContinue : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedTime == null) return;
    final hour = _selectedTime!.hour;
    final period = hour < 12 ? 'AM' : 'PM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final slot = TimeSlot(
      id: '${hour.toString().padLeft(2, '0')}:00',
      displayLabel: '$h12:00 $period',
      hour: hour,
      isAvailable: true,
    );
    ref.read(bookingCartProvider.notifier).selectSchedule(_today, slot);
    context.push('/booking/location');
  }
}

// ── Time slot picker ───────────────────────────────────────────────────────────

class _TimeSlotPicker extends StatefulWidget {
  final String? therapistId;
  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final void Function(TimeOfDay) onTimeSelected;

  const _TimeSlotPicker({
    required this.therapistId,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  State<_TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<_TimeSlotPicker> {
  Set<String> _bookedSlots = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  @override
  void didUpdateWidget(_TimeSlotPicker old) {
    super.didUpdateWidget(old);
    if (old.therapistId != widget.therapistId ||
        old.selectedDate != widget.selectedDate) {
      _fetchBookedSlots();
    }
  }

  Future<void> _fetchBookedSlots() async {
    if (widget.therapistId == null) {
      if (mounted) setState(() { _bookedSlots = {}; _loading = false; });
      return;
    }
    if (mounted) setState(() => _loading = true);

    final rows = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from('bookings')
          .select('scheduled_at')
          .eq('therapist_id', widget.therapistId!)
          .not('status', 'in', '("completed","cancelled")')
          .gte('scheduled_at', WIB.startOfTodayUtc().toIso8601String())
          .lt('scheduled_at', WIB.endOfTodayUtc().toIso8601String()),
    );

    final slots = <String>{};
    for (final b in rows) {
      final scheduledAt = b['scheduled_at'] as String?;
      if (scheduledAt != null) {
        final wib = WIB.toWIB(DateTime.parse(scheduledAt));
        final key =
            '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')}';
        debugPrint('Added booked slot: $key (${WIB.formatTime(DateTime.parse(scheduledAt))} WIB)');
        slots.add(key);
      }
    }
    debugPrint('All booked slots for ${widget.therapistId}: $slots');

    if (mounted) setState(() { _bookedSlots = slots; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final now = WIB.now();
    final timeSlots = <TimeOfDay>[
      for (int h = 8; h <= 23; h++) TimeOfDay(hour: h, minute: 0),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: timeSlots.map((slot) {
        final slotKey =
            '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
        final isBooked = _bookedSlots.contains(slotKey);
        // Past = slot hour has already started today
        final isPast = slot.hour <= now.hour;
        final isSelected = widget.selectedTime?.hour == slot.hour;

        debugPrint('Slot $slotKey — booked: $isBooked, past: $isPast');

        final Color bgColor;
        final Color borderColor;
        final Color textColor;

        if (isPast) {
          bgColor = const Color(0xFFF5F0E8).withValues(alpha: 0.4);
          borderColor = const Color(0xFFEBE4D9).withValues(alpha: 0.4);
          textColor = const Color(0xFF2C2C2A).withValues(alpha: 0.3);
        } else if (isBooked) {
          bgColor = const Color(0xFFFFF3CD);
          borderColor = const Color(0xFFFFE082);
          textColor = const Color(0xFF856404);
        } else if (isSelected) {
          bgColor = const Color(0xFF4E523B);
          borderColor = const Color(0xFF4E523B);
          textColor = Colors.white;
        } else {
          bgColor = const Color(0xFFF5F0E8);
          borderColor = const Color(0xFFEBE4D9);
          textColor = const Color(0xFF2C2C2A);
        }

        return GestureDetector(
          onTap: isPast
              ? null
              : isBooked
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'This time slot is already booked for this therapist'),
                          duration: Duration(seconds: 3),
                        ),
                      )
                  : () => widget.onTimeSelected(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slotKey,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                    decoration: isPast
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: textColor,
                  ),
                ),
                if (isBooked) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Booked',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Legend dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
