import 'package:cloud_firestore/cloud_firestore.dart';

class ProduitModel {
  final String id;
  final String name;
  final String range;
  final String description;
  final String composition;
  final String indications;
  final String contraindications;
  final List<String> tags;
  final String thumbnailUrl;
  final String fichePdfUrl;
  final List<String> targetRoles;

  const ProduitModel({
    required this.id,
    required this.name,
    required this.range,
    required this.description,
    required this.composition,
    required this.indications,
    required this.contraindications,
    required this.tags,
    required this.thumbnailUrl,
    required this.fichePdfUrl,
    required this.targetRoles,
  });

  factory ProduitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProduitModel(
      id: doc.id,
      name: d['name'] ?? '',
      range: d['range'] ?? '',
      description: d['description'] ?? '',
      composition: d['composition'] ?? '',
      indications: d['indications'] ?? '',
      contraindications: d['contraindications'] ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      thumbnailUrl: d['thumbnailUrl'] ?? '',
      fichePdfUrl: d['fichePdfUrl'] ?? '',
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
    );
  }
}
