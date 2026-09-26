import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/therapist_profile.dart';
import '../../../shared/providers/auth_provider.dart';
import 'all_reviews_page.dart';
import 'profile_provider.dart';
import 'reviews_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _bioController = TextEditingController();
  final _specialtiesController = TextEditingController();
  bool _isEditing = false;
  bool? _localAvailability;

  @override
  void dispose() {
    _bioController.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  void _initFromProfile(TherapistProfile profile) {
    if (!_isEditing) {
      _bioController.text = profile.bio ?? '';
      _specialtiesController.text = profile.specialties.join(', ');
      _localAvailability ??= profile.isAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(therapistProfileProvider);
    final updateState = ref.watch(profileUpdateProvider);

    ref.listen<AsyncValue<void>>(profileUpdateProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          if (_isEditing) {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          profileAsync.whenOrNull(
                data: (profile) => profile != null
                    ? TextButton(
                        onPressed: updateState.isLoading
                            ? null
                            : () {
                                if (_isEditing) {
                                  _saveProfile(profile);
                                } else {
                                  setState(() {
                                    _isEditing = true;
                                    _initFromProfile(profile);
                                  });
                                }
                              },
                        child: Text(
                          _isEditing ? 'Save' : 'Edit',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : null,
              ) ??
              const SizedBox(),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          _localAvailability ??= profile.isAvailable;
          return _buildContent(profile, updateState);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load profile', style: GoogleFonts.inter()),
        ),
      ),
    );
  }

  void _saveProfile(TherapistProfile profile) {
    final specialties = _specialtiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    ref.read(profileUpdateProvider.notifier).save(
          therapistProfileId: profile.id,
          bio: _bioController.text.trim(),
          specialties: specialties,
          isAvailable: _localAvailability ?? profile.isAvailable,
        );
  }

  Widget _buildContent(TherapistProfile profile, AsyncValue<void> updateState) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      onRefresh: () async {
        ref.invalidate(therapistProfileProvider);
        ref.invalidate(reviewsProvider);
        ref.invalidate(reviewsCountProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(profile),
          const SizedBox(height: 16),
          _buildStatsRow(profile),
          const SizedBox(height: 16),
          _buildAvailabilityCard(profile),
          const SizedBox(height: 16),
          _buildBioCard(profile),
          const SizedBox(height: 16),
          _buildSpecialtiesCard(profile),
          const SizedBox(height: 16),
          _buildReviewsSection(),
          const SizedBox(height: 24),
          if (updateState.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            _buildLogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildProfileHeader(TherapistProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Therapist', // role label — matches DB role value
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(TherapistProfile profile) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Rating',
            value: profile.rating > 0 ? profile.displayRating : 'N/A',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF39C12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: 'Total Reviews',
            value: profile.totalReviews.toString(),
            icon: Icons.reviews_outlined,
            iconColor: const Color(0xFF3498DB),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard(TherapistProfile profile) {
    final isAvail = _localAvailability ?? profile.isAvailable;

    return _SectionCard(
      title: 'Availability',
      icon: Icons.access_time_outlined,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvail ? 'Available for Orders' : 'Not Available',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAvail
                      ? 'Clients can book you now'
                      : 'You won\'t receive new bookings',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvail,
            onChanged: (val) => setState(() => _localAvailability = val),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(TherapistProfile profile) {
    return _SectionCard(
      title: 'Bio',
      icon: Icons.person_outline,
      child: _isEditing
          ? TextField(
              controller: _bioController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tell clients about yourself...',
                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            )
          : Text(
              profile.bio?.isNotEmpty == true
                  ? profile.bio!
                  : 'No bio added yet. Tap Edit to add one.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: profile.bio?.isNotEmpty == true
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
    );
  }

  Widget _buildSpecialtiesCard(TherapistProfile profile) {
    return _SectionCard(
      title: 'Specialties',
      icon: Icons.spa_outlined,
      child: _isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _specialtiesController,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Swedish Massage, Deep Tissue, Aromatherapy',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Separate specialties with commas',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          : profile.specialties.isEmpty
              ? Text(
                  'No specialties added yet.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.specialties
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3)),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ))
                      .toList(),
                ),
    );
  }

  Widget _buildReviewsSection() {
    final reviewsAsync = ref.watch(reviewsProvider);
    final countAsync = ref.watch(reviewsCountProvider);
    final totalCount = countAsync.value ?? 0;

    return _SectionCard(
      title: 'Reviews',
      icon: Icons.star_rounded,
      child: reviewsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, __) => Text(
          'Could not load reviews',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'No reviews yet.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            );
          }

          final avg = reviews.fold(0.0, (sum, r) => sum + r.rating) /
              reviews.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFC9A96E),
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($totalCount ${totalCount == 1 ? 'review' : 'reviews'})',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...reviews.map((r) => _ReviewCard(review: r)),
              if (totalCount > 5) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllReviewsPage(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View all $totalCount reviews',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: () => _showLogoutDialog(),
      icon: const Icon(Icons.logout, color: AppColors.error),
      label: Text(
        'Sign Out',
        style: GoogleFonts.inter(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(profileUpdateProvider.notifier).signOut();
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][review.createdAt.month];
    final dateStr = '$month ${review.createdAt.day}, ${review.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
