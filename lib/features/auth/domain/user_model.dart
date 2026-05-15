import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { pharmacien, medecin, kine, commercial }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.pharmacien:
        return 'Pharmacien';
      case UserRole.medecin:
        return 'Médecin';
      case UserRole.kine:
        return 'Kinésithérapeute';
      case UserRole.commercial:
        return 'Délégué commercial';
    }
  }

  String get value {
    switch (this) {
      case UserRole.pharmacien:
        return 'pharmacien';
      case UserRole.medecin:
        return 'medecin';
      case UserRole.kine:
        return 'kine';
      case UserRole.commercial:
        return 'commercial';
    }
  }
}

UserRole userRoleFromString(String value) {
  switch (value.toLowerCase()) {
    case 'medecin':
      return UserRole.medecin;
    case 'kine':
      return UserRole.kine;
    case 'commercial':
      return UserRole.commercial;
    default:
      return UserRole.pharmacien;
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String region;
  final String level;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.region,
    required this.level,
    required this.createdAt,
  });

  String get firstName => name.split(' ').first;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: userRoleFromString(data['role'] ?? 'pharmacien'),
      region: data['region'] ?? '',
      level: data['level'] ?? 'Débutant',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role.value,
        'region': region,
        'level': level,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class RolePermissions {
  static const Map<UserRole, List<String>> modules = {
    UserRole.pharmacien: [
      'dashboard', 'formations', 'challenges', 'menu',
      'actualites', 'produits', 'pubs', 'packs', 'factures', 'labo',
    ],
    UserRole.medecin: [
      'dashboard', 'formations', 'challenges', 'menu',
      'actualites', 'produits', 'pubs', 'labo',
    ],
    UserRole.kine: [
      'dashboard', 'formations', 'challenges', 'menu',
      'actualites', 'produits', 'pubs', 'labo',
    ],
    UserRole.commercial: [
      'dashboard', 'formations', 'challenges', 'menu',
      'actualites', 'produits', 'pubs', 'packs', 'factures', 'labo', 'analytics',
    ],
  };

  static bool hasAccess(UserRole role, String module) {
    return modules[role]?.contains(module) ?? false;
  }

  static List<String> getModules(UserRole role) {
    return modules[role] ?? [];
  }
}
