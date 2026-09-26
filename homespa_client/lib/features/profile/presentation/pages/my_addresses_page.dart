import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/address_repository.dart';
import '../../domain/entities/saved_address.dart';

class MyAddressesPage extends ConsumerWidget {
  const MyAddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(savedAddressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Addresses',
          style: AppTypography.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/profile/addresses/add');
          ref.invalidate(savedAddressesProvider);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Could not load addresses',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(savedAddressesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 56,
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No saved addresses',
                        style: AppTypography.headingSmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      'Save your home or office address\nfor faster booking.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final addr = addresses[i];
              return _AddressCard(
                address: addr,
                onSetDefault: () async {
                  final userId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  await ref
                      .read(addressRepositoryProvider)
                      .setDefault(addr.id, userId);
                  ref.invalidate(savedAddressesProvider);
                },
                onDelete: () => _confirmDelete(context, ref, addr),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, SavedAddress addr) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove "${addr.label}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(addressRepositoryProvider)
                  .deleteAddress(addr.id);
              ref.invalidate(savedAddressesProvider);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: address.isDefault ? null : onSetDefault,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_labelIcon(address.label),
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  'Default',
                                  style: AppTypography.overline.copyWith(
                                      color: AppColors.primary, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address.notes != null && address.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        address.notes!,
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (!address.isDefault) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap to set as default',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 20),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _labelIcon(String label) => switch (label.toLowerCase()) {
      'home' => Icons.home_rounded,
      'office' || 'work' => Icons.business_rounded,
      _ => Icons.location_on_rounded,
    };
