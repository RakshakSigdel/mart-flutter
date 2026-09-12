import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';

/// A failed report is shown as unavailable, never as a zero total.
class DashboardSection<T> extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.value,
    required this.onRetry,
    required this.builder,
  });
  final String title;
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T) builder;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    data: builder,
    loading: () => AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xl),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          const Text('Loading summary…', style: AppTypography.bodySmall),
        ],
      ),
    ),
    error: (error, _) => AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          Text(
            error is ApiException
                ? error.message
                : 'Could not load this summary.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
