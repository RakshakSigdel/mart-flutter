import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../services/category_image_search_service.dart';

/// Returns the selected public image URL, or null when dismissed.
class CategoryImageSearchDialog extends StatefulWidget {
  const CategoryImageSearchDialog({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<CategoryImageSearchDialog> createState() =>
      _CategoryImageSearchDialogState();
}

class _CategoryImageSearchDialogState extends State<CategoryImageSearchDialog> {
  late final _query = TextEditingController(text: widget.initialQuery);
  final _service = CategoryImageSearchService();
  List<CategorySearchImage> _images = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  @override
  void dispose() {
    _requestId++;
    _query.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a category or product to search for.');
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
      _images = [];
    });
    try {
      final images = await _service.search(query);
      if (!mounted || requestId != _requestId) return;
      setState(() => _images = images);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = 'Could not search images. Please try again.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find a category image',
                      style: AppTypography.title,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _query,
                hint: 'Search Wikimedia Commons images',
                prefixIcon: Icons.search_rounded,
                suffixIcon: Icons.arrow_forward_rounded,
                onSuffixTap: _search,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search public images, then select one for this category.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildResults()),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Images are from Wikimedia Commons. Check the source and license before use.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmptyState.error(
            message: _error,
            onAction: _search,
            compact: true,
          ),
        ),
      );
    }
    if (_images.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: Icons.image_search_outlined,
            title: _searched ? 'No images found' : 'Search for an image',
            message: _searched
                ? 'Try another search term.'
                : 'Try the category name or a product type.',
            compact: true,
          ),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return _ImageResultTile(
          image: image,
          onSelect: () => Navigator.of(context).pop(image.imageUrl),
        );
      },
    );
  }
}

class _ImageResultTile extends StatelessWidget {
  const _ImageResultTile({required this.image, required this.onSelect});

  final CategorySearchImage image;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppBorderRadius.radiusL,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.iconInactive,
                    ),
                  ),
                  if (image.sourceUrl != null)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: IconButton.filledTonal(
                        tooltip: 'Copy image source link',
                        icon: const Icon(Icons.link_rounded, size: 18),
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: image.sourceUrl!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                  Text(
                    image.license ?? 'Check license',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
