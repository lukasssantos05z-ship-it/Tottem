import 'dart:convert';

class Collaborator {
  final String id;
  final String name;
  final String registration;
  final String sector;
  final List<double> faceEmbedding;
  final bool isActive;

  Collaborator({
    required this.id,
    required this.name,
    required this.registration,
    required this.sector,
    required this.faceEmbedding,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registration': registration,
      'sector': sector,
      'face_embedding': jsonEncode(faceEmbedding),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Collaborator.fromMap(Map<String, dynamic> map) {
    return Collaborator(
      id: map['id'] as String,
      name: map['name'] as String,
      registration: map['registration'] as String,
      sector: map['sector'] as String,
      faceEmbedding: (jsonDecode(map['face_embedding'] as String) as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
