import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/rider_assignment.dart';
import '../../../shared/widgets/status_badge.dart';
import 'rider_provider.dart';

const _bg = Color(0xFFFAF7F2);
const _card = Color(0xFFF5F0E8);
const _primary = Color(0xFF4E523B);
const _divider = Color(0xFFE0D9CE);
const _textPrimary = Color(0xFF1A1A14);
const _textSecondary = Color(0xFF7A7565);

class RiderAssignmentDetailPage extends ConsumerWidget {
  final String assignmentId;

  const RiderAssignmentDetailPage({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(assignmentDetailProvider(assignmentId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: assignmentAsync.maybeWhen(
          data: (a) => Text(
            a?.shortId ?? 'Assignment',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          orElse: () => const Text('Assignment'),
        ),
      ),
      body: assignmentAsync.when(
        data: (assignment) {
          if (assignment == null) {
            return Center(
              child: Text(
                'Assignment not found',
                style: GoogleFonts.inter(color: _textSecondary),
              ),
            );
          }
          return _buildContent(assignment);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (_, __) => Center(
          child: Text(
            'Failed to load assignment',
            style: GoogleFonts.inter(color: _textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(RiderAssignment assignment) {
    debugPrint('[UI] Assignment id: ${assignment.id}');
    debugPrint('[UI] Therapist name: ${assignment.therapistName}');
    debugPrint('[UI] Therapist phone: ${assignment.therapistPhone}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(assignment),
          const SizedBox(height: 16),
          _buildDetailsCard(assignment),
          if (assignment.therapistName != null &&
              assignment.therapistName!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTherapistCard(assignment),
          ],
          if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotesCard(assignment.notes!),
          ],
          if (assignment.isCompleted) ...[
            const SizedBox(height: 16),
            _buildCompletedBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(RiderAssignment assignment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              StatusBadge(status: assignment.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(RiderAssignment assignment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (assignment.scheduledAt != null) ...[
            _detailRow(
              Icons.schedule_outlined,
              'Scheduled',
              DateFormat('EEEE, d MMM yyyy • HH:mm')
                  .format(assignment.scheduledAt!),
            ),
            const SizedBox(height: 14),
          ],
          if (assignment.address != null) ...[
            _detailRow(
              Icons.location_on_outlined,
              'Address',
              assignment.address!,
            ),
            const SizedBox(height: 8),
            _mapsButton(assignment.address!),
            const SizedBox(height: 14),
          ],
          if (assignment.clientName != null)
            _detailRow(
              Icons.person_outlined,
              'Client',
              assignment.clientName!,
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistCard(RiderAssignment assignment) {
    final phone = assignment.therapistPhone ?? '';
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final waNumber = clean.startsWith('0') ? '62${clean.substring(1)}' : clean;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE4D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THERAPIST',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: const Color(0xFF6B6B68),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0x1A4E523B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_rounded,
                    color: Color(0xFF4E523B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.therapistName!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B6B68),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('https://wa.me/$waNumber');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF2ECC71), size: 28),
          const SizedBox(width: 12),
          Text(
            'Assignment completed',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A7A42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
