import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../providers/booking_cart.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_step_indicator.dart';

// ── Booking window (all times WIB) ────────────────────────────────────────────

/// Earliest start time of the day, in minutes after midnight (08:00).
const int _kOpenMinutes = 8 * 60;

/// Latest start time of the day, in minutes after midnight (23:00).
const int _kCloseMinutes = 23 * 60;

/// Bookings must start at least this long after "now".
const int _kLeadMinutes = 50;

/// How many days past today can be booked.
const int _kDaysAhead = 30;

/// Minute wheel step (00, 10, 20 …).
const int _kMinuteStep = 10;

// ── Wheel styling ─────────────────────────────────────────────────────────────

const double _kItemExtent = 56;
const int _kVisibleItems = 5;
const Color _kCream = AppColors.surface; // #F5F0E8

/// Schedule step: a Date | Hour | Minutes wheel picker. Times before
/// now + [_kLeadMinutes] or outside opening hours snap to the earliest valid
/// time, and the chosen slot is checked against the therapist's bookings.
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  late List<DateTime> _dates; // WIB calendar days (UTC-flagged, midnight)
  late int _earliestMinutes; // minutes after midnight on _dates.first
  late int _dateIndex;
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _dateCtrl;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  Timer? _clock;

  static const int _firstHour = _kOpenMinutes ~/ 60;
  static const int _lastHour = _kCloseMinutes ~/ 60;
  static final List<int> _minutes = [
    for (int m = 0; m < 60; m += _kMinuteStep) m,
  ];

  @override
  void initState() {
    super.initState();
    _rebuildWindow();

    // Resume a time picked earlier in this flow, if it is still valid.
    final saved = ref.read(bookingCartProvider).scheduledAt;
    var start = (_dates.first, _earliestMinutes);
    if (saved != null) {
      final w = WIB.toWIB(saved);
      final day = DateTime.utc(w.year, w.month, w.day);
      final i = _dates.indexOf(day);
      final mins = w.hour * 60 + w.minute;
      if (i >= 0 && mins >= _minMinutesFor(i) && mins <= _kCloseMinutes) {
        start = (day, mins);
      }
    }
    _dateIndex = _dates.indexOf(start.$1);
    _hour = start.$2 ~/ 60;
    _minute = start.$2 % 60;

    _dateCtrl = FixedExtentScrollController(initialItem: _dateIndex);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour - _firstHour);
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _minutes.indexOf(_minute),
    );

    // Keep the minimum honest while the page stays open.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _dateCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  // ── Window maths ────────────────────────────────────────────────────────────

  /// Recomputes the earliest bookable moment and the selectable dates.
  void _rebuildWindow() {
    final now = WIB.now();
    const stepMs = _kMinuteStep * 60 * 1000;
    final leadMs = now
        .add(const Duration(minutes: _kLeadMinutes))
        .millisecondsSinceEpoch;
    // Round up to the next step. WIB is a whole number of steps from UTC,
    // so rounding the epoch value rounds the WIB clock too.
    final earliest = DateTime.fromMillisecondsSinceEpoch(
      (leadMs + stepMs - 1) ~/ stepMs * stepMs,
      isUtc: true,
    );

    var day = DateTime.utc(earliest.year, earliest.month, earliest.day);
    var mins = earliest.hour * 60 + earliest.minute;
    if (mins < _kOpenMinutes) {
      mins = _kOpenMinutes;
    } else if (mins > _kCloseMinutes) {
      day = day.add(const Duration(days: 1));
      mins = _kOpenMinutes;
    }

    final today = DateTime.utc(now.year, now.month, now.day);
    final last = today.add(const Duration(days: _kDaysAhead));
    _dates = [
      for (var d = day; !d.isAfter(last); d = d.add(const Duration(days: 1))) d,
    ];
    _earliestMinutes = mins;
  }

  int _minMinutesFor(int dateIndex) =>
      dateIndex == 0 ? _earliestMinutes : _kOpenMinutes;

  bool _hourEnabled(int hour) {
    final min = _minMinutesFor(_dateIndex);
    return hour * 60 + _minutes.last >= min && hour * 60 <= _kCloseMinutes;
  }

  bool _minuteEnabled(int minute) {
    final t = _hour * 60 + minute;
    return t >= _minMinutesFor(_dateIndex) && t <= _kCloseMinutes;
  }

  DateTime get _selectedWib =>
      _dates[_dateIndex].add(Duration(hours: _hour, minutes: _minute));

  /// Snaps the wheels forward/back to the nearest valid time.
  void _normalize() {
    final t = (_hour * 60 + _minute).clamp(
      _minMinutesFor(_dateIndex),
      _kCloseMinutes,
    );
    final h = t ~/ 60;
    final m = t % 60;
    if (h == _hour && m == _minute) return;
    setState(() {
      _hour = h;
      _minute = m;
    });
    _animate(_hourCtrl, h - _firstHour);
    _animate(_minuteCtrl, _minutes.indexOf(m));
  }

  void _onTick() {
    final selectedDay = _dates[_dateIndex];
    setState(() {
      _rebuildWindow();
      final i = _dates.indexOf(selectedDay);
      _dateIndex = i >= 0 ? i : 0;
    });
    if (_dateCtrl.hasClients && _dateCtrl.selectedItem != _dateIndex) {
      _dateCtrl.jumpToItem(_dateIndex);
    }
    _normalize();
  }

  void _animate(FixedExtentScrollController c, int index) {
    if (!c.hasClients || c.selectedItem == index) return;
    c.animateToItem(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(bookingCartProvider);
    final therapist = cart.therapist;
    final availability = _checkAvailability(cart);

    return FlowScaffold(
      title: 'Select Date & Time',
      header: const BookingStepIndicator(currentStep: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(kFlowGutter, 20, kFlowGutter, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryBanner(selectedWib: _selectedWib),
            const SizedBox(height: 24),
            _buildPicker(),
            if (_packageIdOf(cart) != null) ...[
              const SizedBox(height: 16),
              _AvailabilityNote(
                state: availability,
                therapistName: therapist?.name ?? 'Your therapist',
              ),
            ],
          ],
        ),
      ),
      bottomBar: FlowPrimaryButton(
        label: 'Continue',
        onTap: availability.blocksContinue ? null : _onContinue,
      ),
    );
  }

  /// The platform package being booked (a duration variant IS a package).
  String? _packageIdOf(BookingCart cart) =>
      cart.selectedDuration?.id ?? cart.freeRewardTreatmentId;

  /// The chosen time is checked against GET /availability — the same slot
  /// engine the WhatsApp bot uses, so the answer reflects every channel's
  /// bookings. The database still rejects a snatched slot on commit (409).
  _Availability _checkAvailability(BookingCart cart) {
    final packageId = _packageIdOf(cart);
    if (packageId == null) return _Availability.free;

    final day = _dates[_dateIndex];
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final slotsAsync = ref.watch(
      availabilityProvider((packageId: packageId, date: dateStr)),
    );
    return slotsAsync.when(
      loading: () => _Availability.checking,
      error: (e, _) {
        debugPrint('Availability check failed: $e');
        return _Availability.unknown;
      },
      data: (slots) {
        final therapistId = cart.therapist?.id;
        final startUtc = WIB.wibToUtc(_selectedWib);
        // Slots are proposed on the hour; the containing hour must be free.
        final hourStartUtc = DateTime.utc(
          startUtc.year,
          startUtc.month,
          startUtc.day,
          startUtc.hour,
        );
        final ok = slots.any(
          (s) =>
              (therapistId == null || s.therapistId == therapistId) &&
              s.startUtc.isAtSameMomentAs(hourStartUtc),
        );
        return ok ? _Availability.free : _Availability.conflict;
      },
    );
  }

  Widget _buildPicker() {
    final dateFmt = DateFormat('MMM d');
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 5, child: _ColumnHeader('Date')),
              const Expanded(flex: 3, child: _ColumnHeader('Hour')),
              const Expanded(flex: 3, child: _ColumnHeader('Minutes')),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _kItemExtent * _kVisibleItems,
            child: Stack(
              children: [
                // Highlighted centre row with hairlines above and below.
                Center(
                  child: Container(
                    height: _kItemExtent,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _Wheel(
                        controller: _dateCtrl,
                        itemCount: _dates.length,
                        onChanged: (i) => setState(() => _dateIndex = i),
                        onSettled: _normalize,
                        itemBuilder: (i) {
                          final d = _dates[i];
                          return _DateItem(
                            label: _dayLabel(d),
                            date: '${dateFmt.format(d)}${_ordinal(d.day)}',
                            selected: i == _dateIndex,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Wheel(
                        controller: _hourCtrl,
                        itemCount: _lastHour - _firstHour + 1,
                        onChanged: (i) =>
                            setState(() => _hour = _firstHour + i),
                        onSettled: _normalize,
                        itemBuilder: (i) {
                          final h = _firstHour + i;
                          return _ValueItem(
                            text: h.toString().padLeft(2, '0'),
                            selected: h == _hour,
                            enabled: _hourEnabled(h),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Wheel(
                        controller: _minuteCtrl,
                        itemCount: _minutes.length,
                        onChanged: (i) => setState(() => _minute = _minutes[i]),
                        onSettled: _normalize,
                        itemBuilder: (i) {
                          final m = _minutes[i];
                          return _ValueItem(
                            text: m.toString().padLeft(2, '0'),
                            selected: m == _minute,
                            enabled: _minuteEnabled(m),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final offset = d.difference(_todayWib()).inDays;
    if (offset == 0) return 'TODAY';
    if (offset == 1) return 'TOMORROW';
    return DateFormat('EEEE').format(d).toUpperCase();
  }

  static DateTime _todayWib() {
    final n = WIB.now();
    return DateTime.utc(n.year, n.month, n.day);
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  void _onContinue() {
    // The minimum may have moved while the user was deciding.
    final picked = _selectedWib;
    _onTick();
    if (_selectedWib != picked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That time has passed — moved to the earliest slot.'),
        ),
      );
      return;
    }

    final scheduledAtUtc = WIB.wibToUtc(_selectedWib);
    debugPrint(
      'Schedule picked: ${DateFormat('y-MM-dd HH:mm').format(_selectedWib)} '
      'WIB → $scheduledAtUtc',
    );
    ref.read(bookingCartProvider.notifier).selectSchedule(scheduledAtUtc);
    context.push('/booking/location');
  }
}

// ── Availability ──────────────────────────────────────────────────────────────

enum _Availability {
  free,
  checking,
  conflict,
  unknown;

  bool get blocksContinue => this == checking || this == conflict;
}

class _AvailabilityNote extends StatelessWidget {
  final _Availability state;
  final String therapistName;

  const _AvailabilityNote({required this.state, required this.therapistName});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String text) = switch (state) {
      _Availability.free => (
        Icons.check_circle_outline_rounded,
        kFlowMuted,
        '$therapistName is free at this time.',
      ),
      _Availability.checking => (
        Icons.hourglass_top_rounded,
        kFlowMuted,
        'Checking $therapistName’s schedule…',
      ),
      _Availability.conflict => (
        Icons.error_outline_rounded,
        const Color(0xFFFFB4A8),
        'This therapist is already booked around that time. Please choose '
            'another time or therapist.',
      ),
      _Availability.unknown => (
        Icons.info_outline_rounded,
        kFlowMuted,
        'Couldn’t check $therapistName’s schedule. We’ll confirm with you.',
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: flowBody(13, color: color, height: 1.35)),
        ),
      ],
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final DateTime selectedWib;
  const _SummaryBanner({required this.selectedWib});

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(kFlowRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('EEE, d MMM y').format(selectedWib)}'
                  '  ·  ${DateFormat('HH:mm').format(selectedWib)} WIB',
                  style: flowHeading(16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Book up to $_kDaysAhead days ahead. Earliest time is '
                  '$_kLeadMinutes minutes from now.',
                  style: flowBody(12, color: kFlowMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wheel pieces ──────────────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  final String text;
  const _ColumnHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: flowBody(12, weight: FontWeight.w500, color: kFlowMuted),
  );
}

/// One wheel column. Drags with touch or mouse, snaps to items, and reports
/// when scrolling settles so invalid picks can be corrected.
class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onChanged;
  final VoidCallback onSettled;
  final Widget Function(int index) itemBuilder;

  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.onChanged,
    required this.onSettled,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          // Defer so the final onSelectedItemChanged lands first.
          WidgetsBinding.instance.addPostFrameCallback((_) => onSettled());
          return false;
        },
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _kItemExtent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.8,
          perspective: 0.002,
          overAndUnderCenterOpacity: 0.45,
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.animateToItem(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              ),
              child: Center(child: itemBuilder(i)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final String label;
  final String date;
  final bool selected;

  const _DateItem({
    required this.label,
    required this.date,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          style: flowBody(
            9.5,
            weight: FontWeight.w600,
            color: selected ? _kCream : kFlowMuted,
          ).copyWith(letterSpacing: 1.1),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          maxLines: 1,
          style: selected
              ? flowHeading(19, color: Colors.white)
              : flowBody(14, color: Colors.white70),
        ),
      ],
    );
  }
}

class _ValueItem extends StatelessWidget {
  final String text;
  final bool selected;
  final bool enabled;

  const _ValueItem({
    required this.text,
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        text,
        style: flowBody(
          15,
          color: Colors.white.withValues(alpha: 0.22),
        ).copyWith(decoration: TextDecoration.lineThrough),
      );
    }
    return Text(
      text,
      style: selected
          ? flowHeading(24, color: Colors.white)
          : flowBody(16, color: Colors.white70),
    );
  }
}
