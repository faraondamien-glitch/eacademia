import 'package:cloud_firestore/cloud_firestore.dart';

enum ActuCategory {
  produit,
  evenement,
  commercial,
  sante,
  info,
}

extension ActuCategoryExtension on ActuCategory {
  String get label => switch (this) {
        ActuCategory.produit => 'Produit',
        ActuCategory.evenement => 'Événement',
        ActuCategory.commercial => 'Commercial',
        ActuCategory.sante => 'Santé',
        ActuCategory.info => 'Info',
      };

  String get value => switch (this) {
        ActuCategory.produit => 'produit',
        ActuCategory.evenement => 'evenement',
        ActuCategory.commercial => 'commercial',
        ActuCategory.sante => 'sante',
        ActuCategory.info => 'info',
      };
}

ActuCategory actuCategoryFromString(String v) =>
    ActuCategory.values.firstWhere(
      (e) => e.value == v.toLowerCase(),
      orElse: () => ActuCategory.info,
    );

class ActuModel {
  final String id;
  final String title;
  final String body;
  final ActuCategory category;
  final String? imageUrl;
  final String author;
  final DateTime publishedAt;
  final List<String> targetRoles; // [] = tous
  final bool isPinned;

  const ActuModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.imageUrl,
    required this.author,
    required this.publishedAt,
    required this.targetRoles,
    required this.isPinned,
  });

  factory ActuModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ActuModel(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      category: actuCategoryFromString(d['category'] ?? 'info'),
      imageUrl: d['imageUrl'] as String?,
      author: d['author'] ?? 'Granions',
      publishedAt:
          (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
      isPinned: d['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'category': category.value,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'author': author,
        'publishedAt': Timestamp.fromDate(publishedAt),
        'targetRoles': targetRoles,
        'isPinned': isPinned,
      };
}
