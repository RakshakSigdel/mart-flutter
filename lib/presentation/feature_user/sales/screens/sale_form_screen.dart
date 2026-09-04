import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../widgets/sale_form.dart';

/// Full-page "ring up a sale" screen — pushed on top of [SalesScreen]
/// rather than shown as a dialog, matching the pattern used for every
/// other form in this app; this one especially, since the dynamic item
/// list needs real room.
class SaleFormScreen extends StatelessWidget {
  const SaleFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Ring up sale'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const SaleForm(),
          ),
        ),
      ),
    );
  }
}
