/// Data representing one item in the POS cart.
class PosCartItem {
  const PosCartItem({
    required this.productId,
    required this.productName,
    required this.sellingUnitId,
    required this.sellingUnitLabel,
    this.quantity = 1,
    required this.rate,
    this.discountAmount = 0,
  });

  final int productId;
  final String productName;
  final int sellingUnitId;
  final String sellingUnitLabel;
  final double quantity;
  final double rate;
  final double discountAmount;

  double get lineTotal => (quantity * rate) - discountAmount;

  PosCartItem copyWith({
    int? productId,
    String? productName,
    int? sellingUnitId,
    String? sellingUnitLabel,
    double? quantity,
    double? rate,
    double? discountAmount,
  }) {
    return PosCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sellingUnitId: sellingUnitId ?? this.sellingUnitId,
      sellingUnitLabel: sellingUnitLabel ?? this.sellingUnitLabel,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
