import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';
import '../../../treatments/presentation/widgets/category_chip.dart';
import '../../domain/entities/order_filters.dart';

/// Opens the History filter sheet. Resolves to the applied filters (Reset
/// applies [OrderFilters.none]), or null when dismissed without applying.
Future<OrderFilters?> showOrderFilterSheet(
  BuildContext context,
  OrderFilters current,
) {
  return showModalBottomSheet<OrderFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => OrderFilterSheet(initial: current),
  );
}

class OrderFilterSheet extends ConsumerStatefulWidget {
  final OrderFilters initial;
  const OrderFilterSheet({super.key, required this.initial});

  @override
  ConsumerState<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends ConsumerState<OrderFilterSheet> {
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;
  late final Set<String> _categoryIds = {...widget.initial.categoryIds};

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.darkOliveLight,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  void _apply() => Navigator.of(
    context,
  ).pop(OrderFilters(from: _from, to: _to, categoryIds: {..._categoryIds}));

  void _reset() => Navigator.of(context).pop(OrderFilters.none);

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final labelStyle = GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textOnDark,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkOlive,
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
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter Orders',
            style: const TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text('Date', style: labelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  value: _from,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: () => setState(() => _from = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'To',
                  value: _to,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: () => setState(() => _to = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Category', style: labelStyle),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cream,
                ),
              ),
            ),
            error: (_, __) => Text(
              'Couldn’t load categories.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textOnDarkMuted,
              ),
            ),
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  CategoryChip(
                    label: c.name,
                    isSelected: _categoryIds.contains(c.id),
                    onTap: () => setState(() {
                      if (!_categoryIds.remove(c.id)) _categoryIds.add(c.id);
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Reset', style: GoogleFonts.montserrat()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.darkOliveLight,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.textOnDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value == null
                          ? 'Any date'
                          : DateFormat('d MMM yyyy').format(value!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                IconButton(
                  tooltip: 'Clear $label date',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: onClear,
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
