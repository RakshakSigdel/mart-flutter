import 'package:flutter/material.dart';

import '../core/core.dart';

/// A visual catalogue of every design-system token and widget in `core/`.
///
/// Not part of the app's real navigation — wired up temporarily in
/// `main.dart` so the whole system can be eyeballed in one pass before any
/// screen is built against it. Safe to delete once real screens exist.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _switch = true;
  bool _checkbox = true;
  int _radio = 0;
  bool _expanded = false;
  bool _loading = false;
  int _counter = 0;
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Section(
            title: 'Colors',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                _Swatch('primary', AppColors.primary),
                _Swatch('primaryDark', AppColors.primaryDark),
                _Swatch('primaryDeep', AppColors.primaryDeep, dark: true),
                _Swatch('primarySoft', AppColors.primarySoft),
                _Swatch('accent', AppColors.accent, dark: true),
                _Swatch('accentElevated', AppColors.accentElevated, dark: true),
                _Swatch('accentSoft', AppColors.accentSoft),
                _Swatch('surface', AppColors.surface),
                _Swatch('surfaceSunken', AppColors.surfaceSunken),
                _Swatch('border', AppColors.border),
                _Swatch('borderStrong', AppColors.borderStrong),
                _Swatch('error', AppColors.error, dark: true),
                _Swatch('errorSoft', AppColors.errorSoft),
                _Swatch('success', AppColors.success, dark: true),
                _Swatch('successSoft', AppColors.successSoft),
                _Swatch('warning', AppColors.warning, dark: true),
                _Swatch('warningSoft', AppColors.warningSoft),
                _Swatch('info', AppColors.info, dark: true),
                _Swatch('infoSoft', AppColors.infoSoft),
                _Swatch('tertiary', AppColors.tertiary, dark: true),
                _Swatch('tertiarySoft', AppColors.tertiarySoft),
              ],
            ),
          ),

          _Section(
            title: 'Gradients',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _GradientSwatch('primary', AppGradients.primary),
                _GradientSwatch('accent', AppGradients.accent),
                _GradientSwatch('background', AppGradients.background),
                _GradientSwatch('hero', AppGradients.hero),
                _GradientSwatch('heroDark', AppGradients.heroDark),
                _GradientSwatch('softPrimary', AppGradients.softPrimary),
                _GradientSwatch('shimmer', AppGradients.shimmer),
              ],
            ),
          ),

          _Section(
            title: 'Shadows',
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                _ShadowSwatch('card', AppShadows.card),
                _ShadowSwatch('panel', AppShadows.panel),
                _ShadowSwatch('button', AppShadows.button),
                _ShadowSwatch('modal', AppShadows.modal),
                _ShadowSwatch('floating', AppShadows.floating),
                _ShadowSwatch('soft', AppShadows.soft),
              ],
            ),
          ),

          _Section(
            title: 'Radius',
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _RadiusSwatch('xs', AppBorderRadius.radiusXS),
                _RadiusSwatch('sm', AppBorderRadius.radiusSM),
                _RadiusSwatch('md', AppBorderRadius.radiusMD),
                _RadiusSwatch('lg', AppBorderRadius.radiusL),
                _RadiusSwatch('xl', AppBorderRadius.radiusXL),
                _RadiusSwatch('full', AppBorderRadius.radiusFull),
              ],
            ),
          ),

          _Section(
            title: 'Spacing',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpacingRow('xs', AppSpacing.xs),
                _SpacingRow('sm', AppSpacing.sm),
                _SpacingRow('smMd', AppSpacing.smMd),
                _SpacingRow('md', AppSpacing.md),
                _SpacingRow('mdLg', AppSpacing.mdLg),
                _SpacingRow('lg', AppSpacing.lg),
                _SpacingRow('xl', AppSpacing.xl),
                _SpacingRow('xxl', AppSpacing.xxl),
                _SpacingRow('xxxl', AppSpacing.xxxl),
              ],
            ),
          ),

          _Section(
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('display', style: AppTypography.display),
                Text('displaySmall', style: AppTypography.displaySmall),
                Text('heading', style: AppTypography.heading),
                Text('title', style: AppTypography.title),
                Text('subtitle', style: AppTypography.subtitle),
                Text('body — the quick brown fox', style: AppTypography.body),
                Text(
                  'bodySmall — the quick brown fox',
                  style: AppTypography.bodySmall,
                ),
                Text('label', style: AppTypography.label),
                Text('labelSmall', style: AppTypography.labelSmall),
                Text('EYEBROW', style: AppTypography.eyebrow),
                Text('caption', style: AppTypography.caption),
                Text('Rs 1,249.00', style: AppTypography.price),
                Text('Rs 249.00', style: AppTypography.priceSmall),
                Text('Rs 1,999.00', style: AppTypography.priceStruck),
                Text('128', style: AppTypography.metric),
              ],
            ),
          ),

          _Section(
            title: 'Buttons — variants',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(label: 'Primary', onPressed: () {}),
                AppButton(
                  label: 'Secondary',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Dark',
                  variant: AppButtonVariant.dark,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Danger',
                  variant: AppButtonVariant.danger,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Ghost',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {},
                ),
                const AppButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),

          _Section(
            title: 'Buttons — sizes, icons, loading',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: 'Small',
                  size: AppButtonSize.sm,
                  onPressed: () {},
                ),
                AppButton(label: 'Medium', onPressed: () {}),
                AppButton(
                  label: 'Large',
                  size: AppButtonSize.lg,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Add',
                  leading: const Icon(Icons.add),
                  onPressed: () {},
                ),
                AppButton(
                  label: 'View all',
                  variant: AppButtonVariant.ghost,
                  trailing: const Icon(Icons.arrow_forward, size: 16),
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Loading',
                  isLoading: _loading,
                  onPressed: () async {
                    setState(() => _loading = true);
                    await Future<void>.delayed(AppAnimations.slow);
                    if (mounted) setState(() => _loading = false);
                  },
                ),
              ],
            ),
          ),
          AppButton.expanded(label: 'Expanded button', onPressed: () {}),

          _Section(
            title: 'Badges',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                AppBadge(label: 'Neutral'),
                AppBadge(label: 'Primary', tone: AppBadgeTone.primary),
                AppBadge(label: 'In stock', tone: AppBadgeTone.success),
                AppBadge(
                  label: 'Pending',
                  tone: AppBadgeTone.warning,
                  icon: Icons.schedule,
                ),
                AppBadge(label: 'Out of stock', tone: AppBadgeTone.error),
                AppBadge(label: 'Info', tone: AppBadgeTone.info),
                AppBadge(label: 'Featured', tone: AppBadgeTone.tertiary),
                AppBadge.solid(label: '-20%', tone: AppBadgeTone.error),
                AppBadge.solid(label: 'New', tone: AppBadgeTone.primary),
              ],
            ),
          ),

          _Section(
            title: 'Cards / Panel',
            child: Column(
              children: [
                const AppCard(child: Text('AppCard — bordered, subtle shadow')),
                const SizedBox(height: AppSpacing.smMd),
                AppCard(
                  onTap: () => AppSnackBar.info(context, 'Card tapped'),
                  child: const Text('AppCard — tappable (ripple)'),
                ),
                const SizedBox(height: AppSpacing.smMd),
                const AppSoftCard(
                  child: Text('AppSoftCard — flat, muted background'),
                ),
                const SizedBox(height: AppSpacing.smMd),
                const AppPanel(
                  child: Text('AppPanel — deep shadow, hero/profile areas'),
                ),
              ],
            ),
          ),

          _Section(
            title: 'Section titles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionTitle(
                  eyebrow: 'National league',
                  title: 'Top Players',
                  trailing: AppButton(
                    label: 'View all',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    onPressed: () {},
                    trailing: const Icon(Icons.chevron_right, size: 16),
                  ),
                ),
                const AppSubSectionTitle(title: 'Match statistics'),
              ],
            ),
          ),

          _Section(
            title: 'Text fields',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _textController,
                    label: 'Email',
                    hint: 'you@example.com',
                    prefixIcon: Icons.mail_outline,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  const AppTextField(label: 'Password', obscureText: true),
                  const SizedBox(height: AppSpacing.smMd),
                  const AppTextField(
                    label: 'Disabled',
                    enabled: false,
                    initialValue: 'Cannot edit this',
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  const AppTextField.multiline(
                    label: 'Delivery notes',
                    hint: 'Ring the bell twice',
                  ),
                ],
              ),
            ),
          ),

          _Section(
            title: 'Dropdowns',
            child: Column(
              children: [
                AppDropdownField<String>(
                  label: 'Payment method',
                  value: null,
                  hint: 'Select method',
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    DropdownMenuItem(
                      value: 'FONEPAY',
                      child: Text('Fonepay'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: AppSpacing.smMd),
                AppSearchableDropdownField<String>(
                  label: 'Assign staff (searchable)',
                  selectedItem: null,
                  hint: 'Select a staff member',
                  searchHint: 'Search by name…',
                  items: const ['Aarav', 'Bibek', 'Chandra', 'Divya', 'Esha'],
                  itemLabel: (s) => s,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),

          _Section(
            title: 'Selection controls',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Switch'),
                  value: _switch,
                  onChanged: (v) => setState(() => _switch = v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Checkbox'),
                  value: _checkbox,
                  onChanged: (v) => setState(() => _checkbox = v ?? false),
                ),
                RadioGroup<int>(
                  groupValue: _radio,
                  onChanged: (v) => setState(() => _radio = v!),
                  child: const Column(
                    children: [
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Radio A'),
                        value: 0,
                      ),
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Radio B'),
                        value: 1,
                      ),
                    ],
                  ),
                ),
                Chip(label: const Text('Chip')),
              ],
            ),
          ),

          _Section(
            title: 'Snack bars & modals',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'Success toast',
                  size: AppButtonSize.sm,
                  onPressed: () =>
                      AppSnackBar.success(context, 'Order placed'),
                ),
                AppButton(
                  label: 'Error toast',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.danger,
                  onPressed: () => AppSnackBar.error(
                    context,
                    'Payment failed',
                    action: 'Retry',
                    onAction: () {},
                  ),
                ),
                AppButton(
                  label: 'Warning toast',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      AppSnackBar.warning(context, 'Low stock on 3 items'),
                ),
                AppButton(
                  label: 'Open dialog',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.dark,
                  onPressed: () => showAppDialog<void>(
                    context: context,
                    title: 'Add Player',
                    content: const Text('Dialog content goes here.'),
                  ),
                ),
                AppButton(
                  label: 'Open bottom sheet',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => showAppModal<void>(
                    context: context,
                    title: 'Filter',
                    content: const Text('Sheet content goes here.'),
                  ),
                ),
                AppButton(
                  label: 'Loading overlay',
                  size: AppButtonSize.sm,
                  onPressed: () async {
                    showAppLoadingOverlay(context, message: 'Placing order…');
                    await Future<void>.delayed(AppAnimations.slow);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          _Section(
            title: 'Empty & loading states',
            child: Column(
              children: [
                AppEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  message: 'Browse the catalogue to add your first item.',
                  actionLabel: 'Start shopping',
                  onAction: () {},
                  compact: true,
                ),
                AppEmptyState.error(onAction: () {}, compact: true),
                const AppEmptyState.noResults(compact: true),
                const SizedBox(height: AppSpacing.md),
                const AppLoader(message: 'Loading orders…'),
                const SizedBox(height: AppSpacing.md),
                const AppCardSkeleton(),
                const SizedBox(height: AppSpacing.smMd),
                const AppListSkeleton(itemCount: 2),
              ],
            ),
          ),

          _Section(
            title: 'Animations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppFadeIn(child: AppSoftCard(child: Text('AppFadeIn'))),
                const SizedBox(height: AppSpacing.smMd),
                const AppFadeSlideIn(
                  child: AppSoftCard(child: Text('AppFadeSlideIn')),
                ),
                const SizedBox(height: AppSpacing.smMd),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppStaggered(
                      index: i,
                      child: AppSoftCard(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text('AppStaggered item $i'),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: AppPressable(
                        onTap: () => setState(() => _counter++),
                        child: AppCard(
                          child: Center(
                            child: Text('AppPressable — tap me ($_counter)'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.smMd),
                    Expanded(
                      child: AppSwitcher(
                        child: Text(
                          '$_counter',
                          key: ValueKey(_counter),
                          style: AppTypography.metric,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.smMd),
                AppButton(
                  label: _expanded ? 'Collapse' : 'Expand',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                AppExpandable(
                  expanded: _expanded,
                  child: const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: AppCard(
                      child: Text('AppExpandable — revealed content'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.smMd),
                Row(
                  children: const [
                    AppShimmer.circle(size: 40),
                    SizedBox(width: AppSpacing.smMd),
                    Expanded(child: AppShimmer(height: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ─── Section scaffolding (showcase-only, not part of the design system) ───

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: title),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, {this.dark = false});

  final String name;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: AppTypography.caption.copyWith(
          color: dark ? AppColors.textInverse : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch(this.name, this.gradient);

  final String name;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 64,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ShadowSwatch extends StatelessWidget {
  const _ShadowSwatch(this.name, this.shadow);

  final String name;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppBorderRadius.radiusMD,
            boxShadow: shadow,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(name, style: AppTypography.caption),
      ],
    );
  }
}

class _RadiusSwatch extends StatelessWidget {
  const _RadiusSwatch(this.name, this.radius);

  final String name;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: radius,
            border: Border.all(color: AppColors.primaryDeep),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(name, style: AppTypography.caption),
      ],
    );
  }
}

class _SpacingRow extends StatelessWidget {
  const _SpacingRow(this.name, this.value);

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('$name (${value.toInt()})', style: AppTypography.caption),
          ),
          Container(
            width: value,
            height: 14,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
