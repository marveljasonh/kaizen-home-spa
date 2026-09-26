import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isSaving = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      debugPrint('Current user: ${client.auth.currentUser?.id}');
      debugPrint('Current session: ${client.auth.currentSession?.accessToken != null}');
      String? avatarUrl;

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final path = 'avatars/${client.auth.currentUser!.id}.jpg';
        await client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      }

      final userId = client.auth.currentUser!.id;
      debugPrint('Saving profile for user: $userId');
      try {
        final response = await client.from('profiles').update({
          'full_name': name,
          'phone': _phoneCtrl.text.trim(),
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }).eq('id', userId);
        debugPrint('Update response: $response');
      } catch (e) {
        debugPrint('Update error: $e');
        rethrow;
      }

      await ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      }
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
    final authState = ref.watch(authNotifierProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        children: [
          // ── Avatar picker ─────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _pickedImage != null
                      ? null
                      : (user?.avatarUrl != null
                          ? CachedNetworkImageProvider(user!.avatarUrl!)
                          : null),
                  child: _pickedImage != null
                      ? ClipOval(
                          child: Image.network(
                            _pickedImage!.path,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _InitialsAvatar(user: user, size: 52),
                          ),
                        )
                      : (user?.avatarUrl == null
                          ? _InitialsAvatar(user: user, size: 52)
                          : null),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickImage,
              child: const Text('Change Photo'),
            ),
          ),
          const SizedBox(height: 28),

          // ── Fields ────────────────────────────────────────────────────────
          Text('Full Name',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 20),

          Text('Phone Number',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+62 812 3456 7890',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 20),

          Text('Email',
              style: text.labelMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            enabled: false,
            controller:
                TextEditingController(text: user?.email ?? ''),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceVariant
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.email_outlined),
              helperText: 'Email cannot be changed',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared initials avatar ─────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final dynamic user;
  final double size;
  const _InitialsAvatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      _initials(),
      style: TextStyle(
        color: AppColors.primary,
        fontSize: size * 0.55,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _initials() {
    final name = user?.name as String?;
    if (name == null || name.isEmpty) {
      final email = user?.email as String? ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
