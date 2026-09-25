import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/page_response.dart';
import '../../../../data/models/models_user/return_note_model.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/return_note_provider.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../widgets/return_note_card.dart';

const _dateRanges = <String, String>{
  'ALL_TIME': 'All time',
  'TODAY': 'Today',
  'YESTERDAY': 'Yesterday',
  'THIS_WEEK': 'This week',
  'THIS_MONTH': 'This month',
  'THIS_YEAR': 'This year',
};

class ReturnNotesScreen extends ConsumerStatefulWidget {
  const ReturnNotesScreen({super.key, required this.kind});
  final ReturnKind kind;

  @override
  ConsumerState<ReturnNotesScreen> createState() => _ReturnNotesScreenState();
}

class _ReturnNotesScreenState extends ConsumerState<ReturnNotesScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer();
  List<VendorModel> _vendors = const [];
  int? _vendorId;
  String _dateRange = 'ALL_TIME';
  int _page = 0;
  int _generation = 0;
  PageResponse<ReturnNoteModel>? _results;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    if (widget.kind == ReturnKind.purchase) Future.microtask(_loadVendors);
  }

  Future<void> _loadVendors() async {
    try {
      final vendors = await ref
          .read(vendorRemoteDataSourceProvider)
          .selection();
      if (mounted) setState(() => _vendors = vendors);
    } on ApiException catch (e) {
      if (e.type == ApiFailureType.unauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(returnNoteRemoteDataSourceProvider)
          .list(
            widget.kind,
            search: _search.text,
            vendorId: _vendorId,
            dateRange: _dateRange,
            page: _page,
          );
      if (mounted && generation == _generation)
        setState(() => _results = results);
    } on ApiException catch (e) {
      if (e.type == ApiFailureType.unauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      if (mounted && generation == _generation)
        setState(() => _error = e.message);
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _error = 'Could not load returns.');
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  void _filter() {
    _page = 0;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(widget.kind.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _search,
                      hint: widget.kind == ReturnKind.sale
                          ? 'Credit note, invoice or customer'
                          : 'Debit note, bill or vendor',
                      prefixIcon: Icons.search,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => _debouncer.run(_filter),
                      onSubmitted: (_) {
                        _debouncer.cancel();
                        _filter();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        DropdownButton<String>(
                          value: _dateRange,
                          items: _dateRanges.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _dateRange = value);
                              _filter();
                            }
                          },
                        ),
                        if (widget.kind == ReturnKind.purchase)
                          SizedBox(
                            width: 220,
                            child: AppSearchableDropdownField<VendorModel>(
                              selectedItem: _vendorId == null
                                  ? null
                                  : _vendors
                                        .where((v) => v.id == _vendorId)
                                        .firstOrNull,
                              items: _vendors,
                              itemLabel: (vendor) => vendor.name,
                              hint: 'All vendors',
                              onChanged: (vendor) {
                                setState(() => _vendorId = vendor?.id);
                                _filter();
                              },
                            ),
                          ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppEmptyState.error(message: _error, onAction: _load),
                ),
              if (!_loading && _error == null)
                Expanded(
                  child: results == null || results.content.isEmpty
                      ? const Center(child: Text('No return notes found.'))
                      : ListView.builder(
                          itemCount: results.content.length,
                          itemBuilder: (context, index) => AppCard(
                            child: ReturnNoteCard(
                              note: results.content[index],
                              kind: widget.kind,
                              compact: true,
                            ),
                          ),
                        ),
                ),
              if (results != null && _error == null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Text('${results.totalElements} notes'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Previous page',
                        onPressed: _loading || _page == 0
                            ? null
                            : () {
                                _page--;
                                _load();
                              },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Page ${results.pageNumber + 1} of ${results.totalPages}',
                      ),
                      IconButton(
                        tooltip: 'Next page',
                        onPressed: _loading || results.last
                            ? null
                            : () {
                                _page++;
                                _load();
                              },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReturnNoteDetailScreen extends ConsumerWidget {
  const ReturnNoteDetailScreen({
    super.key,
    required this.kind,
    required this.id,
  });
  final ReturnKind kind;
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(_returnNoteProvider((kind, id)));
    return Scaffold(
      appBar: AppBar(title: Text(kind.noteLabel)),
      body: note.when(
        loading: () => const AppLoader(),
        error: (error, _) => AppEmptyState.error(
          message: error is ApiException
              ? error.message
              : 'Could not load ${kind.noteLabel.toLowerCase()}.',
          onAction: () => ref.invalidate(_returnNoteProvider((kind, id))),
        ),
        data: (value) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppCard(
                  child: ReturnNoteCard(note: value, kind: kind),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.expanded(
                  label: kind == ReturnKind.sale
                      ? 'View original sale'
                      : 'View original purchase',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(
                    kind == ReturnKind.sale
                        ? Routes.saleDetail(value.originalId)
                        : Routes.purchaseDetail(value.originalId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _returnNoteProvider = FutureProvider.autoDispose
    .family<ReturnNoteModel, (ReturnKind, int)>((ref, key) async {
      try {
        return await ref
            .read(returnNoteRemoteDataSourceProvider)
            .getById(key.$1, key.$2);
      } on ApiException catch (e) {
        if (e.type == ApiFailureType.unauthorized) {
          await ref.read(authControllerProvider.notifier).logout();
        }
        rethrow;
      }
    });
