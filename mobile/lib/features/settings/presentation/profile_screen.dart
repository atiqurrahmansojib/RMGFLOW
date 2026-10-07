import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';

/// Document 7 (#4): who is signed in, with which roles (Doc 5), which server
/// the app talks to, and sign-out. Read from the access token — display only;
/// every permission is re-checked by the server.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign in again on this device.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final email = user?.email ?? 'Signed in';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          GradientHeader(
            margin: EdgeInsets.zero,
            eyebrow: 'Signed in as',
            title: email,
            subtitle: user == null ? null : 'User #${user.id}',
            icon: Icons.person_rounded,
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: Text(
                email.isEmpty ? '?' : email[0].toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            bottom: Row(
              children: [
                Expanded(child: HeaderStat(value: '${user?.roles.length ?? 0}', label: 'Roles')),
              ],
            ),
          ),
          const SectionHeader('Roles',
              subtitle: 'What you can see and do is decided by these roles', icon: Icons.verified_user_outlined),
          if (user == null || user.roles.isEmpty)
            const AppCard(child: Text('No roles found in your session.'))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in user.roles)
                  StatusChip(
                    'ACTIVE',
                    label: AppStatus.humanize(r.replaceFirst('ROLE_', '')),
                    tone: StatusTone.progress,
                  ),
              ],
            ),
          const SectionHeader('App', icon: Icons.phone_android_rounded),
          const AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                InfoRow(label: 'Server', value: AppConfig.apiBaseUrl, copyable: true),
                InfoRow(label: 'Theme', value: 'Follows your device (light / dark)'),
                InfoRow(label: 'Downloads', value: 'Reports are saved to Download/RMGFlow'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            variant: ButtonVariant.danger,
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
