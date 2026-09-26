import '../../../../../core/utils/timezone_helper.dart';
import '../entities/time_slot.dart';

class GetAvailableSlotsUseCase {
  const GetAvailableSlotsUseCase();

  List<TimeSlot> call(DateTime date) {
    final now = WIB.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return List.generate(12, (i) {
      final hour = 8 + i; // 8 AM – 7 PM
      final isAvailable = !isToday || hour > now.hour + 1;
      final period = hour < 12 ? 'AM' : 'PM';
      final h = hour > 12 ? hour - 12 : hour;
      return TimeSlot(
        id: '${hour.toString().padLeft(2, '0')}:00',
        displayLabel: '$h:00 $period',
        hour: hour,
        isAvailable: isAvailable,
      );
    });
  }
}
