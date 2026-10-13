import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/material_i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../providers/branch_contacts_provider.dart';

/// Contact Us: one card per branch with its WhatsApp number. The numbers come
/// from the `branches` table and are managed in the admin dashboard.
class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchContactsProvider);

    return FlowScaffold(
      title: 'Contact Us',
      subtitle: 'Kaizen Home Spa',
      body: RefreshIndicator(
        color: AppColors.fg,
        backgroundColor: AppColors.page,
        onRefresh: () async {
          ref.invalidate(branchContactsProvider);
          await ref.read(branchContactsProvider.future).catchError((_) => <BranchContact>[]);
        },
        child: branches.when(
          loading: () => const _Message(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          error: (_, _) => _Message(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't load branch contacts",
            body: 'Check your connection and pull down to try again.',
            action: FlowSecondaryButton(
              label: 'Try again',
              onTap: () => ref.invalidate(branchContactsProvider),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const _Message(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No contact numbers yet',
                body: 'Our branch contacts will appear here soon.',
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                kFlowGutter,
                20,
                kFlowGutter,
                32,
              ),
              children: [
                Text(
                  'Chat with the branch nearest to you on WhatsApp. Tap a card to start a conversation.',
                  style: flowBody(14, color: kFlowMuted, height: 1.5),
                ),
                const SizedBox(height: 18),
                for (final b in list) ...[
                  _BranchCard(branch: b),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchContact branch;
  const _BranchCard({required this.branch});

  Future<void> _open(BuildContext context, Uri uri, String failMessage) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  void _whatsApp(BuildContext context) {
    final text = tr(
      "Hello Kaizen Home Spa ${branch.name}, I'd like to ask about your services.",
    );
    final uri = Uri.https('wa.me', '/${branch.whatsappNumber}', {'text': text});
    _open(context, uri, tr("Couldn't open WhatsApp"));
  }

  void _call(BuildContext context) {
    final uri = Uri(scheme: 'tel', path: '+${branch.whatsappNumber}');
    _open(context, uri, tr("Couldn't start the call"));
  }

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(branch.name, style: flowHeading(20, height: 1.2)),
          if (branch.address != null) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.location_on_outlined, text: branch.address!),
          ],
          if (branch.operatingHours != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: branch.operatingHours!,
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone_outlined, text: branch.displayPhone),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FlowPrimaryButton(
                  label: 'WhatsApp',
                  onTap: () => _whatsApp(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FlowSecondaryButton(
                  label: 'Call',
                  onTap: () => _call(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: kFlowMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: flowBody(13, color: kFlowMuted, height: 1.4)),
        ),
      ],
    );
  }
}

/// Centred state (loading / empty / error) that stays pull-to-refreshable.
class _Message extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? body;
  final Widget? action;
  final Widget? child;

  const _Message({this.icon, this.title, this.body, this.action, this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (child != null) child!,
                  if (icon != null) Icon(icon, size: 44, color: kFlowMuted),
                  if (title != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: flowHeading(20, height: 1.2),
                    ),
                  ],
                  if (body != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      body!,
                      textAlign: TextAlign.center,
                      style: flowBody(14, color: kFlowMuted, height: 1.5),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(width: 200, child: action!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
