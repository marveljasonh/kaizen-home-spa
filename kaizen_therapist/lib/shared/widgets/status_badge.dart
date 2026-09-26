import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (label, bg, text) = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _getStatusInfo(String status) {
    switch (status) {
      case 'assigned':
      case 'therapist_assigned':
        return ('Assigned', const Color(0xFFE8EAE0), const Color(0xFF4E523B));
      case 'on_the_way':
        return ('On The Way', const Color(0xFFFFF3CD), const Color(0xFF856404));
      case 'arrived':
        return ('Arrived', const Color(0xFFFFE8D0), const Color(0xFF8A4A00));
      case 'in_progress':
        return ('In Progress', const Color(0xFFD1F2EA), const Color(0xFF0D6F52));
      case 'completed':
        return ('Completed', const Color(0xFFD4EDDA), const Color(0xFF155724));
      case 'pending':
        return ('Pending', const Color(0xFFFFF3CD), const Color(0xFF856404));
      case 'cancelled':
        return ('Cancelled', const Color(0xFFF8D7DA), const Color(0xFF842029));
      default:
        return (
          status.replaceAll('_', ' ').toUpperCase(),
          const Color(0xFFE8EAE0),
          const Color(0xFF4E523B),
        );
    }
  }
}
