import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Temporary destination for settings while tax and mart setup is unavailable.
class SettingsComingSoonScreen extends StatelessWidget {
  const SettingsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const AppCard(
            child: AppEmptyState(
              icon: Icons.settings_outlined,
              title: 'Tax & mart settings are coming soon',
              message: 'This page is temporarily unavailable. Please check back later.',
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}
