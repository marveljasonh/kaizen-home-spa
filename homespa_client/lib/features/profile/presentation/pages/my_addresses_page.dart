import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/widgets/kaizen_page.dart';
import '../../data/address_repository.dart';
import '../../domain/entities/saved_address.dart';

// My Addresses: hero with back button, glass address cards (label pill,
// address, Edit / Delete), white "Add New Address" bar.

class MyAddressesPage extends ConsumerWidget {
  const MyAddressesPage({super.key});

  /// Add (no [address]) or edit, then reload the list.
  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, [
    SavedAddress? address,
  ]) async {
    await context.push('/profile/addresses/add', extra: address);
    ref.invalidate(savedAddressesProvider);
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(savedAddressesProvider);
    try {
      await ref.read(savedAddressesProvider.future);
    } catch (_) {
      // The error state is shown in the list.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(savedAddressesProvider);
    final hasAddresses = addressesAsync.value?.isNotEmpty ?? false;

    return KaizenHeroPage(
      label: 'Account',
      title: 'My Addresses',
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      onRefresh: () => _refresh(ref),
      // The empty state has its own add button.
      bottomBar: hasAddresses
          ? FlowPrimaryButton(
              label: 'Add New Address',
              onTap: () => _openEditor(context, ref),
            )
          : null,
      children: addressesAsync.when(
        loading: () => const [_CardSkeleton(), _CardSkeleton()],
        error: (_, _) => [
          _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load addresses',
            hint: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(savedAddressesProvider),
          ),
        ],
        data: (addresses) => addresses.isEmpty
            ? [
                _EmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'No saved addresses',
                  hint: 'Save your home or office address for faster booking.',
                  actionLabel: 'Add New Address',
                  onAction: () => _openEditor(context, ref),
                ),
              ]
            : [
                for (final addr in addresses) ...[
                  KaizenGutter(
                    _AddressCard(
                      address: addr,
                      onSetDefault: () async {
                        await ref
                            .read(addressRepositoryProvider)
                            .setDefault(addr.id);
                        ref.invalidate(savedAddressesProvider);
                      },
                      onEdit: () => _openEditor(context, ref, addr),
                      onDelete: () => _confirmDelete(context, ref, addr),
                    ),
                  ),
                  const SizedBox(height: kPageCardGap),
                ],
              ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress addr,
  ) async {
    final ok = await showKaizenConfirmDialog(
      context,
      title: 'Delete Address',
      message: 'Remove "${addr.label}" from your saved addresses?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(addressRepositoryProvider).deleteAddress(addr.id);
    ref.invalidate(savedAddressesProvider);
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final notes = address.notes;
    return KaizenGlassCard(
      onTap: address.isDefault ? null : onSetDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_labelIcon(address.label), size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(child: KaizenPill(address.label)),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                const KaizenPill('Default', color: kStatusActive),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.fullAddress,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: flowBody(14, height: 1.4),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: flowBody(12, color: kFlowMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: address.isDefault
                    ? const SizedBox.shrink()
                    : Text(
                        'Tap to set as default',
                        style: flowBody(12, color: kFlowMuted),
                      ),
              ),
              KaizenSmallButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              const SizedBox(width: 10),
              KaizenSmallButton(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                color: kStatusDanger,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon, CalSans heading, Montserrat hint and a white action button.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return KaizenGutter(
      KaizenGlassCard(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: kFlowMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: flowHeading(22, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: flowBody(13, color: kFlowMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            FlowPrimaryButton(label: actionLabel, onTap: onAction),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      kPageGutterLeft,
      0,
      kPageGutterRight,
      kPageCardGap,
    ),
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kGlassCardRadius),
      ),
    ),
  );
}

IconData _labelIcon(String label) => switch (label.toLowerCase()) {
  'home' => Icons.home_outlined,
  'office' || 'work' => Icons.business_outlined,
  _ => Icons.location_on_outlined,
};
