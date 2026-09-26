class SavedAddress {
  final String id;
  final String clientId;
  final String label;
  final String fullAddress;
  final String? notes;
  final bool isDefault;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.clientId,
    required this.label,
    required this.fullAddress,
    this.notes,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        label: json['label'] as String,
        fullAddress: json['full_address'] as String,
        notes: json['notes'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
