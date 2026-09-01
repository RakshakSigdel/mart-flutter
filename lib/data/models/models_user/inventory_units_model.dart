/// What an inventory unit measures. Values match exactly what
/// `/inventory/units` accepts/returns for the `measurementType` field.
enum UnitMeasurementType {
  weight('WEIGHT'),
  volume('VOLUME'),
  count('COUNT'),
  length('LENGTH');

  const UnitMeasurementType(this.apiValue);

  /// The exact string the backend sends/expects.
  final String apiValue;

  static UnitMeasurementType? fromApiValue(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  /// "WEIGHT" -> "Weight", for display only.
  String get label => '${apiValue[0]}${apiValue.substring(1).toLowerCase()}';
}

/// One unit of measure, as returned by every `/inventory/units` endpoint
/// except the plain-string one (remove).
///
/// Unlike staff/mart records, [id] is numeric — this is a small, mart-wide
/// dictionary table, not a UUID-keyed entity.
class InventoryUnitModel {
  const InventoryUnitModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    required this.symbol,
    this.measurementType,
    required this.conversionFactor,
    required this.referenceUnit,
    required this.systemDefined,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String symbol;
  final UnitMeasurementType? measurementType;

  /// How many of this unit make up one of its measurement type's reference
  /// unit (e.g. a "kg" unit might have a conversion factor of 1000 against
  /// a "g" reference unit).
  final double conversionFactor;

  /// Whether this is the base unit its measurement type's other units
  /// convert against. Backend-computed — never sent in a create/update
  /// request.
  final bool referenceUnit;

  /// System-seeded units ship with every mart and can't be edited or
  /// removed — see [isEditable]. Backend-computed, never sent in a
  /// create/update request.
  final bool systemDefined;

  factory InventoryUnitModel.fromJson(Map<String, dynamic> json) {
    return InventoryUnitModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      measurementType: UnitMeasurementType.fromApiValue(
        json['measurementType'] as String?,
      ),
      conversionFactor: (json['conversionFactor'] as num?)?.toDouble() ?? 0,
      referenceUnit: json['referenceUnit'] as bool? ?? false,
      systemDefined: json['systemDefined'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Mirrors the backend's own restriction — "Edit/Remove a *mart-defined*
  /// unit" — so the UI can disable those actions instead of letting the
  /// request round-trip just to be rejected.
  bool get isEditable => !systemDefined;
}

/// Body of both `POST /inventory/units` and `PUT /inventory/units/{id}` —
/// the two requests are identical in shape, so one class covers both.
class UpsertInventoryUnitRequest {
  const UpsertInventoryUnitRequest({
    required this.name,
    required this.symbol,
    required this.measurementType,
    required this.conversionFactor,
  });

  final String name;
  final String symbol;
  final UnitMeasurementType measurementType;
  final double conversionFactor;

  Map<String, dynamic> toJson() => {
        'name': name,
        'symbol': symbol,
        'measurementType': measurementType.apiValue,
        'conversionFactor': conversionFactor,
      };
}

/// `0.000001` -> `"0.000001"`, `1000.0` -> `"1000"` — [double.toString] uses
/// scientific notation for small magnitudes (`1e-6`), which reads as a bug
/// in a form field rather than a value.
String formatConversionFactor(double value) {
  if (value == value.truncateToDouble() && value.abs() < 1e15) {
    return value.truncate().toString();
  }
  final fixed = value.toStringAsFixed(6);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
