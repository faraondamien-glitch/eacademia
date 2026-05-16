import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { pharmacien, preparateur, medecin, kine, commercial }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.pharmacien:
        return 'Pharmacien';
      case UserRole.preparateur:
        return 'Préparateur';
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
      case UserRole.preparateur:
        return 'preparateur';
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
    case 'preparateur':
      return UserRole.preparateur;
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
  final bool isAdmin;

  /// UID du pharmacien manager (pour les préparateurs uniquement).
  final String? managerId;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.region,
    required this.level,
    required this.createdAt,
    this.isAdmin = false,
    this.managerId,
  });

  String get firstName => name.split(' ').first;

  /// Vrai si ce pharmacien peut gérer une équipe de préparateurs.
  bool get canManageTeam => role == UserRole.pharmacien;

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
      isAdmin: data['isAdmin'] as bool? ?? false,
      managerId: data['managerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role.value,
        'region': region,
        'level': level,
        'createdAt': Timestamp.fromDate(createdAt),
        'isAdmin': isAdmin,
        if (managerId != null) 'managerId': managerId,
      };
}

class RolePermissions {
  static const Map<UserRole, List<String>> modules = {
    UserRole.pharmacien: [
      'dashboard', 'formations', 'challenges', 'menu',
      'actualites', 'produits', 'pubs', 'packs', 'factures', 'labo', 'equipe',
    ],
    UserRole.preparateur: [
      'dashboard', 'formations', 'menu',
      'actualites', 'produits', 'pubs', 'labo',
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
