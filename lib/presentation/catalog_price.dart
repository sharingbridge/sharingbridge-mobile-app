import 'package:intl/intl.dart';

/// Formats catalog amounts using the ISO 4217 code from the API/DB.
/// Does not invent a currency when [currencyCode] is missing.
String formatCatalogPrice(num? amount, String? currencyCode) {
  if (amount == null) {
    return '';
  }
  final rounded = amount is int ? amount : amount.round();
  final code = currencyCode?.trim().toUpperCase() ?? '';
  if (code.isEmpty) {
    return '$rounded';
  }
  try {
    return NumberFormat.simpleCurrency(name: code, decimalDigits: 0).format(rounded);
  } catch (_) {
    return '$code $rounded';
  }
}
