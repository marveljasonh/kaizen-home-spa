import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  final String id; // "09:00"
  final String displayLabel; // "9:00 AM"
  final int hour;
  final bool isAvailable;

  const TimeSlot({
    required this.id,
    required this.displayLabel,
    required this.hour,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [id, displayLabel, hour, isAvailable];
}
