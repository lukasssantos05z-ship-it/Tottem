class MealTicket {
  final String id;
  final String collaboratorId;
  final String collaboratorName;
  final String registration;
  final String sector;
  final String mealType;
  final DateTime timestamp;
  final String securityHash;

  MealTicket({
    required this.id,
    required this.collaboratorId,
    required this.collaboratorName,
    required this.registration,
    required this.sector,
    required this.mealType,
    required this.timestamp,
    required this.securityHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collaborator_id': collaboratorId,
      'collaborator_name': collaboratorName,
      'registration': registration,
      'sector': sector,
      'meal_type': mealType,
      'timestamp': timestamp.toIso8601String(),
      'security_hash': securityHash,
    };
  }

  factory MealTicket.fromMap(Map<String, dynamic> map) {
    return MealTicket(
      id: map['id'] as String,
      collaboratorId: map['collaborator_id'] as String,
      collaboratorName: map['collaborator_name'] as String,
      registration: map['registration'] as String,
      sector: map['sector'] as String,
      mealType: map['meal_type'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      securityHash: map['security_hash'] as String,
    );
  }
}
