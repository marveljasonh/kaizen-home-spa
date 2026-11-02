import '../../../../core/i18n/material_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/branch_providers.dart';

/// Opens the "Choose Your Branch" sheet. Selecting a row persists the choice
/// (null = nearest branch, the automatic default) and closes the sheet.
Future<void> showBranchSelectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BranchSelectorSheet(),
  );
}

class BranchSelectorSheet extends ConsumerStatefulWidget {
  const BranchSelectorSheet({super.key});

  @override
  ConsumerState<BranchSelectorSheet> createState() =>
      _BranchSelectorSheetState();
}

class _BranchSelectorSheetState extends ConsumerState<BranchSelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Branch b) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return b.name.toLowerCase().contains(q) ||
        (b.area ?? '').toLowerCase().contains(q) ||
        (b.city ?? '').toLowerCase().contains(q) ||
        (b.serviceAreas ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final selectedId = ref.watch(selectedBranchIdProvider);

    void choose(String? id) {
      ref.read(selectedBranchIdProvider.notifier).select(id);
      Navigator.of(context).pop();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8 +
            MediaQuery.of(context).viewPadding.bottom +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.tint(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Your Branch',
            style: TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: AppColors.fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Availability and your therapist come from this branch.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.fgMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.fg),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('Search branch or area…'),
              hintStyle: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.fgFaint,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.fgMuted,
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: branchesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Couldn’t load branches. Check your connection and try again.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
              data: (branches) {
                final visible = branches.where(_matches).toList();
                return ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    if (_query.isEmpty)
                      _BranchTile(
                        title: 'Nearest branch (auto)',
                        subtitle: 'We pick the branch closest to your address',
                        selected: selectedId == null,
                        onTap: () => choose(null),
                      ),
                    for (final b in visible)
                      _BranchTile(
                        title: b.name,
                        subtitle: b.subtitle,
                        serviceAreas: b.serviceAreaList,
                        selected: b.id == selectedId,
                        onTap: () => choose(b.id),
                      ),
                    if (visible.isEmpty && _query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No branch matches your search.',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: AppColors.fgMuted,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> serviceAreas;
  final bool selected;
  final VoidCallback onTap;

  const _BranchTile({
    required this.title,
    required this.onTap,
    required this.selected,
    this.subtitle,
    this.serviceAreas = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.cardSelected : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? AppColors.fg : AppColors.fgFaint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.fgMuted,
                          ),
                        ),
                      if (serviceAreas.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          // "Serves:" prefix is translated; the area names
                          // themselves come from the dashboard as-is.
                          '${tr('Serves:')} ${serviceAreas.join(' · ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.fgFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable "Branch: <name>" row used at the start of the booking flow and
/// on the Schedule step. Opens [showBranchSelectorSheet].
class BranchPickerRow extends ConsumerWidget {
  const BranchPickerRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(selectedBranchProvider);
    final hasExplicitChoice = ref.watch(selectedBranchIdProvider) != null;
    final label = branch?.name ?? 'Nearest branch (auto)';

    return Material(
      color: AppColors.tint(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showBranchSelectorSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tint(0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 20, color: AppColors.fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Branch',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.fgMuted,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fg,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hasExplicitChoice ? 'Change' : 'Choose',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.fgMuted,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.fgMuted),
            ],
          ),
        ),
      ),
    );
  }
}
