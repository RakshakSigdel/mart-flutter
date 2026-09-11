import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../../providers/providers_user/customer_provider.dart';
import '../widgets/customer_form.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId, this.initialCustomer});

  final int? customerId;
  final CustomerModel? initialCustomer;

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  late Future<CustomerModel?> _customerFuture = _resolveCustomer();

  Future<CustomerModel?> _resolveCustomer() async {
    final id = widget.customerId;
    if (id == null) return null;
    return widget.initialCustomer ??
        ref.read(customerRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit customer' : 'Add customer'),
      ),
      body: FutureBuilder<CustomerModel?>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (widget.isEditing &&
              snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this customer.',
              onAction: () => setState(() => _customerFuture = _resolveCustomer()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CustomerForm(customer: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
