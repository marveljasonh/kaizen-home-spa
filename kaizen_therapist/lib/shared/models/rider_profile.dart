class RiderProfile {
  final String id;
  final String userId;
  final String name;
  final String email;
  final bool isAvailable;
  final String? currentAssignmentId;

  RiderProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.isAvailable,
    this.currentAssignmentId,
  });

  RiderProfile copyWith({bool? isAvailable, String? currentAssignmentId}) {
    return RiderProfile(
      id: id,
      userId: userId,
      name: name,
      email: email,
      isAvailable: isAvailable ?? this.isAvailable,
      currentAssignmentId: currentAssignmentId ?? this.currentAssignmentId,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'R';
  }
}
