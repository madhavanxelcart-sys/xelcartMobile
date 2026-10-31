String formatRupees(double amount) {
  final parts = amount
      .toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)
      .split('.');
  var digits = parts.first;
  if (digits.length > 3) {
    final end = digits.substring(digits.length - 3);
    final start = digits
        .substring(0, digits.length - 3)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{2})+$)'),
          (match) => '${match[1]},',
        );
    digits = '$start,$end';
  }
  return '\u20B9$digits${parts.length == 2 ? '.${parts[1]}' : ''}';
}
