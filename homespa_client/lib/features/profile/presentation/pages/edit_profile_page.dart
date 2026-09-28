import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/widgets/kaizen_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';

// Edit Profile: hero with back button and title; below it the avatar
// picker, glass fields, gender tabs, and a white "Save Changes" bar.

const double _kAvatarSize = 88;

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
  Uint8List? _pickedBytes;

  /// 'male' / 'female' (as saved at sign-up); null until loaded or unset.
  String? _gender;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _loadGender();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Gender isn't on AppUser, so read it from profiles.
  Future<void> _loadGender() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('gender')
          .eq('id', userId)
          .maybeSingle();
      final gender = row?['gender'] as String?;
      if (mounted && _gender == null && gender != null) {
        setState(() => _gender = gender);
      }
    } catch (e) {
      debugPrint('Load gender error: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) {
      setState(() {
        _pickedImage = image;
        _pickedBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      debugPrint('Current user: ${client.auth.currentUser?.id}');
      debugPrint(
        'Current session: ${client.auth.currentSession?.accessToken != null}',
      );
      String? avatarUrl;

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final path = 'avatars/${client.auth.currentUser!.id}.jpg';
        await client.storage
            .from('avatars')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      }

      final userId = client.auth.currentUser!.id;
      debugPrint('Saving profile for user: $userId');
      try {
        final response = await client
            .from('profiles')
            .update({
              'full_name': name,
              'phone': _phoneCtrl.text.trim(),
              if (_gender != null) 'gender': _gender,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            })
            .eq('id', userId);
        debugPrint('Update response: $response');
      } catch (e) {
        debugPrint('Update error: $e');
        rethrow;
      }

      await ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    return KaizenHeroPage(
      label: 'Account',
      title: 'Edit Profile',
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      bottomBar: FlowPrimaryButton(
        label: 'Save Changes',
        isLoading: _isSaving,
        onTap: _save,
      ),
      children: [
        KaizenGutter(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _AvatarPicker(
                  url: user?.avatarUrl,
                  bytes: _pickedBytes,
                  initials: kaizenInitials(user?.name, user?.email ?? ''),
                  onTap: _pickImage,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text('Change Photo'),
                ),
              ),
              const SizedBox(height: kPageCardGap),
              const FlowSectionLabel('Full Name'),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: flowBody(15),
                decoration: const InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              const FlowSectionLabel('Phone Number'),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: flowBody(15),
                decoration: const InputDecoration(
                  hintText: '+62 812 3456 7890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const FlowSectionLabel('Gender'),
              KaizenChoiceTabs<String>(
                options: const [('male', 'Male'), ('female', 'Female')],
                selected: _gender,
                onSelected: (g) => setState(() => _gender = g),
              ),
              const SizedBox(height: 20),
              const FlowSectionLabel('Email'),
              _ReadOnlyField(
                icon: Icons.email_outlined,
                value: user?.email ?? '',
                helper: 'Email cannot be changed',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Avatar with a white camera badge (bottom right).
class _AvatarPicker extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final String initials;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.url,
    required this.bytes,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change photo',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: _kAvatarSize,
          child: Stack(
            children: [
              KaizenAvatar(
                url: url,
                bytes: bytes,
                initials: initials,
                size: _kAvatarSize,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkOlive, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: AppColors.darkOliveLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass box with the same fill and border as the flow text fields, for a
/// value that can't be edited.
class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String value;
  final String helper;

  const _ReadOnlyField({
    required this.icon,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(kFlowRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: kFlowMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: flowBody(15, color: kFlowMuted),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: kFlowMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(helper, style: flowBody(12, color: kFlowMuted)),
        ),
      ],
    );
  }
}
