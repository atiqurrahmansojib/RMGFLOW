import 'package:flutter/material.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../claim/presentation/all_claims_screen.dart';
import '../../financial/presentation/receivables_payables_screen.dart';
import '../../ta/presentation/ta_template_list_screen.dart';
import 'profile_screen.dart';
import 'reference_data_screen.dart';

/// Organization-wide tools that are not tied to one order: the accounts
/// ledgers (Doc 7 #78-79), the claims register (#81), T&A templates (#54),
/// read-only master data (#9-14) and the user's profile (#4).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color color, String title, String subtitle, Widget Function() screen) => LinkCard(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
          onTap: () => _push(context, screen()),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          const GradientHeader(
            margin: EdgeInsets.zero,
            eyebrow: 'Organization-wide',
            title: 'More tools',
            subtitle: 'Ledgers, claims, templates, master data and your profile',
            icon: Icons.apps_rounded,
          ),
          SectionHeader('Finance', icon: AppModules.financial.icon, accentColor: AppModules.financial.color),
          tile(Icons.call_received_rounded, AppColors.success, 'Receivables', 'What buyers owe us, across all orders',
              () => const ReceivablesPayablesScreen()),
          tile(Icons.call_made_rounded, AppColors.warning, 'Payables', 'What we owe factories, across all orders',
              () => const ReceivablesPayablesScreen(initialTab: 1)),
          tile(AppModules.claims.icon, AppModules.claims.color, 'Claims register', 'Every buyer and internal claim',
              () => const AllClaimsScreen()),
          const SectionHeader('Setup', icon: Icons.tune_rounded, accentColor: AppColors.info),
          tile(AppModules.ta.icon, AppModules.ta.color, 'T&A templates', 'Milestone plans orders are generated from',
              () => const TaTemplateListScreen()),
          tile(Icons.dataset_outlined, AppColors.info, 'Reference data',
              'Seasons, currencies, countries, document & defect types', () => const ReferenceDataScreen()),
          const SectionHeader('Account', icon: Icons.person_outline_rounded, accentColor: AppColors.indigo),
          tile(Icons.person_outline_rounded, AppColors.indigo, 'Profile & settings', 'Your roles, server and sign out',
              () => const ProfileScreen()),
        ],
      ),
    );
  }
}
