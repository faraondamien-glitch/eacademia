import 'package:cloud_firestore/cloud_firestore.dart';

enum FactureStatus { paid, pending }

class FactureModel {
  final String id;
  final String userId;
  final String reference;
  final DateTime date;
  final double amount;
  final FactureStatus status;
  final String pdfUrl;

  const FactureModel({
    required this.id,
    required this.userId,
    required this.reference,
    required this.date,
    required this.amount,
    required this.status,
    required this.pdfUrl,
  });

  factory FactureModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FactureModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      reference: d['reference'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (d['amount'] ?? 0.0).toDouble(),
      status: d['status'] == 'paid' ? FactureStatus.paid : FactureStatus.pending,
      pdfUrl: d['pdfUrl'] ?? '',
    );
  }
}
