class SavedAddress {
  final String id;
  final String label;
  final String fullAddress; // platform `line`
  final String? city;
  final String? patokan; // landmark
  final String? notes; // platform `entranceNotes`
  final bool isDefault;
  final double? lat;
  final double? lng;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.city,
    this.patokan,
    this.notes,
    required this.isDefault,
    this.lat,
    this.lng,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    label: (json['label'] as String?) ?? 'Address',
    fullAddress: (json['line'] as String?) ?? '',
    city: json['city'] as String?,
    patokan: json['patokan'] as String?,
    notes: json['entranceNotes'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
