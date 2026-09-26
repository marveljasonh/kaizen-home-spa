import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/status_badge.dart';
import 'schedule_provider.dart';

const _bg = Color(0xFFFAF7F2);
const _card = Color(0xFFF5F0E8);
const _cardBorder = Color(0xFFEBE4D9);
const _primary = Color(0xFF4E523B);
const _divider = Color(0xFFE0D9CE);
const _textPrimary = Color(0xFF1A1A14);
const _textSecondary = Color(0xFF7A7565);
const _gold = Color(0xFFD4A843);

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = WIB.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  void _previousMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      });

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(scheduleBookingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Schedule',
          style: GoogleFonts.inter(
            color: const Color(0xFF2C2C2A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: bookingsAsync.when(
        data: (bookings) => _buildContent(context, bookings),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (_, __) => Center(
          child: Text('Failed to load schedule',
              style: GoogleFonts.inter(color: _textSecondary)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Booking> bookings) {
    final bookingsByDate = <DateTime, List<Booking>>{};
    for (final b in bookings) {
      final date = DateTime(
          b.scheduledTime.year, b.scheduledTime.month, b.scheduledTime.day);
      bookingsByDate.putIfAbsent(date, () => []).add(b);
    }

    final selectedBookings = bookingsByDate[_selectedDate] ?? [];

    return RefreshIndicator(
      color: _primary,
      backgroundColor: _card,
      onRefresh: () async => ref.invalidate(scheduleBookingsProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCalendar(bookingsByDate),
          ),
          if (selectedBookings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(
                      booking: selectedBookings[i],
                      onTap: () => context.push(
                          '/order-detail/${selectedBookings[i].id}'),
                    ),
                  ),
                  childCount: selectedBookings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<Booking>> bookingsByDate) {
    final today = WIB.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final daysInMonth = _daysInMonth(_currentMonth);
    // weekday: 1=Mon … 7=Sun, so offset = weekday - 1
    final offset = _currentMonth.weekday - 1;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _primary),
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _primary),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          // Weekday header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Date grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();

                final day = index - offset + 1;
                final date = DateTime(
                    _currentMonth.year, _currentMonth.month, day);
                final isToday = date == todayNorm;
                final isSelected = date == _selectedDate;
                final isPast = date.isBefore(todayNorm);
                final hasBookings = bookingsByDate.containsKey(date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: _DateCell(
                    day: day,
                    isToday: isToday,
                    isSelected: isSelected,
                    isPast: isPast,
                    hasBookings: hasBookings,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _divider),
          // Selected date label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Text(
                  _selectedDate == todayNorm
                      ? 'Today — ${DateFormat('d MMMM yyyy').format(_selectedDate)}'
                      : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 56, color: _primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No bookings on this day',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select another date to view bookings',
              style: GoogleFonts.inter(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final bool hasBookings;

  const _DateCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.hasBookings,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color? bgColor;
    BoxBorder? border;

    if (isSelected) {
      bgColor = _primary;
      textColor = Colors.white;
      if (isToday) border = Border.all(color: _gold, width: 2);
    } else if (hasBookings && !isPast) {
      bgColor = _primary.withOpacity(0.13);
      textColor = _primary;
      if (isToday) border = Border.all(color: _gold, width: 1.5);
    } else if (isToday) {
      border = Border.all(color: _gold, width: 1.5);
      textColor = _textPrimary;
    } else if (isPast) {
      textColor = _textSecondary.withOpacity(0.35);
    } else {
      textColor = _textPrimary;
    }

    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: border,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected || (hasBookings && !isPast)
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: textColor,
              ),
            ),
            // Dot indicator for dates with bookings (not selected, not past)
            if (hasBookings && !isSelected && !isPast)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor != null ? _primary : _primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = booking.scheduledTime;
    final hourMin = DateFormat('HH:mm').format(time);
    final amPm = DateFormat('a').format(time);
    final treatmentName = booking.treatments.isNotEmpty
        ? booking.treatments.first.name
        : 'Treatment';
    final duration = booking.treatments.isNotEmpty
        ? booking.treatments.first.duration
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hourMin,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    amPm,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Booking info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.clientName ?? 'Client',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    treatmentName,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: _textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (duration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$duration min',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: booking.status),
          ],
        ),
      ),
    );
  }
}
