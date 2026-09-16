import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../widgets/purchase_form.dart';

/// Full-page "record a purchase" screen — pushed on top of
/// [PurchasesScreen] rather than shown as a dialog, matching the pattern
/// used for every other form in this app; this one especially, since the
/// dynamic item list needs real room.
class PurchaseFormScreen extends StatelessWidget {
  const PurchaseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Receive stock / सामान भित्र्याउनुहोस्'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const PurchaseForm(),
          ),
        ),
      ),
    );
  }
}
