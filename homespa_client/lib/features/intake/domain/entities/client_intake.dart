/// A client's answers to the Client Intake Form (`client_intake` row).
class ClientIntake {
  final List<String> healthConditions;
  final List<String> focusAreas;

  /// 'light' | 'medium' | 'firm'
  final String pressure;

  /// Body areas to avoid; null means "No Preference".
  final String? avoidAreas;

  const ClientIntake({
    required this.healthConditions,
    required this.focusAreas,
    required this.pressure,
    this.avoidAreas,
  });

  factory ClientIntake.fromJson(Map<String, dynamic> json) => ClientIntake(
    healthConditions: _strings(json['healthConditions']),
    focusAreas: _strings(json['focusAreas']),
    pressure: json['pressure'] as String? ?? 'medium',
    avoidAreas: json['avoidAreas'] as String?,
  );

  static List<String> _strings(Object? value) =>
      (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
}
