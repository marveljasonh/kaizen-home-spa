String formatRupiah(double amount) {
  final formatted = amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return 'Rp $formatted';
}

/// Short IDR label used on cards and pills, e.g. 175000 → "IDR 175K".
String formatIdrK(double amount) {
  final k = amount / 1000;
  final label = k == k.roundToDouble()
      ? k.toStringAsFixed(0)
      : k.toStringAsFixed(1);
  return 'IDR ${label}K';
}
