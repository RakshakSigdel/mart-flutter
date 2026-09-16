import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../widgets/sale_form.dart';

/// Full-page "ring up a sale" screen — pushed on top of [SalesScreen]
/// rather than shown as a dialog, matching the pattern used for every
/// other form in this app; this one especially, since the dynamic item
/// list needs real room.
class SaleFormScreen extends StatelessWidget {
  const SaleFormScreen({super.key, this.showAppBar = true, this.onSubmitted});

  /// The POS route is rendered inside [AdminShellScreen], which already owns
  /// the app bar. The standalone new-sale route keeps its own app bar.
  final bool showAppBar;

  /// POS is a shell root, so it must navigate rather than pop when the
  /// completed sale is submitted. The standalone new-sale route leaves this
  /// null and retains its normal pop-with-result behavior.
  final ValueChanged<SaleDetailModel>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              title: const Text('Make bill / बिल बनाउनुहोस्'),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: showAppBar ? 640 : 920),
              child: SaleForm(
              onSubmitted:
                  onSubmitted ??
                  (showAppBar
                      ? null
                      : (sale) => context.go(Routes.saleDetail(sale.id))),
            ),
          ),
        ),
      ),
    );
  }
}
