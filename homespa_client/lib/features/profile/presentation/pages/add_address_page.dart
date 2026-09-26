import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/address_repository.dart';

class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  String _selectedLabel = 'Home';
  final _customLabelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;

  static const _presetLabels = ['Home', 'Office', 'Other'];

  @override
  void dispose() {
    _customLabelCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _effectiveLabel =>
      _selectedLabel == 'Other' && _customLabelCtrl.text.trim().isNotEmpty
          ? _customLabelCtrl.text.trim()
          : _selectedLabel;

  Future<void> _save() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a full address')),
      );
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(addressRepositoryProvider).addAddress(
            userId: userId,
            label: _effectiveLabel,
            fullAddress: address,
            notes: _notesCtrl.text.trim().isNotEmpty
                ? _notesCtrl.text.trim()
                : null,
            isDefault: _isDefault,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Address',
          style: AppTypography.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    'Save',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Label ──────────────────────────────────────────────────────────
          Text('Label',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _presetLabels.map((label) {
              final selected = _selectedLabel == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedLabel = label),
                selectedColor: AppColors.primaryLight,
                backgroundColor: AppColors.surface,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          if (_selectedLabel == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customLabelCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _deco(hint: "Custom label (e.g. Parents' House)"),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),

          // ── Full address ────────────────────────────────────────────────────
          Text('Full Address *',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _addressCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: _deco(
              hint:
                  'e.g. Jl. Sudirman No. 45, Kelurahan Senayan, Jakarta Selatan',
            ),
          ),
          const SizedBox(height: 20),

          // ── Notes ──────────────────────────────────────────────────────────
          Text('Notes (optional)',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: _deco(
                hint: 'Gate code, landmarks, floor number…'),
          ),
          const SizedBox(height: 24),

          // ── Set as default ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: SwitchListTile(
                tileColor: Colors.transparent,
                title: Text(
                  'Set as default address',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Used automatically in booking',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                value: _isDefault,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco({required String hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle:
            AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
}
