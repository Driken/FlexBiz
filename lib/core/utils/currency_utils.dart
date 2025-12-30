import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  
  static String format(double? value) {
    if (value == null) return 'R\$ 0,00';
    return _currencyFormat.format(value);
  }
  
  static double? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      // Remove símbolos e formatação
      final cleanValue = value
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      return double.parse(cleanValue);
    } catch (e) {
      return null;
    }
  }
}

