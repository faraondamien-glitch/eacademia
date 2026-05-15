import 'package:cloud_firestore/cloud_firestore.dart';

class PackItem {
  final String name;
  final int quantity;
  final double unitPrice;

  const PackItem({required this.name, required this.quantity, required this.unitPrice});

  factory PackItem.fromMap(Map<String, dynamic> d) => PackItem(
    name: d['name'] ?? '',
    quantity: d['quantity'] ?? 1,
    unitPrice: (d['unitPrice'] ?? 0.0).toDouble(),
  );
}

class PackModel {
  final String id;
  final String name;
  final String icon;
  final List<PackItem> items;
  final double totalPrice;
  final double discountPercent;
  final List<String> targetRoles;

  const PackModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
    required this.totalPrice,
    required this.discountPercent,
    required this.targetRoles,
  });

  double get discountedPrice => totalPrice * (1 - discountPercent / 100);

  factory PackModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PackModel(
      id: doc.id,
      name: d['name'] ?? '',
      icon: d['icon'] ?? '',
      items: (d['items'] as List? ?? []).map((i) => PackItem.fromMap(i as Map<String, dynamic>)).toList(),
      totalPrice: (d['totalPrice'] ?? 0.0).toDouble(),
      discountPercent: (d['discountPercent'] ?? 0.0).toDouble(),
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
    );
  }
}
