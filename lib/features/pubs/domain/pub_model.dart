import 'package:cloud_firestore/cloud_firestore.dart';

class PubModel {
  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final List<String> channels;
  final DateTime broadcastDate;
  final bool isActive;
  final List<String> targetRoles;

  const PubModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.channels,
    required this.broadcastDate,
    required this.isActive,
    required this.targetRoles,
  });

  factory PubModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PubModel(
      id: doc.id,
      title: d['title'] ?? '',
      videoUrl: d['videoUrl'] ?? '',
      thumbnailUrl: d['thumbnailUrl'] ?? '',
      channels: List<String>.from(d['channels'] ?? []),
      broadcastDate: (d['broadcastDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? false,
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
    );
  }
}
