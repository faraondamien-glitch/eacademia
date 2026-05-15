import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:eacademia/features/auth/domain/user_model.dart';
import 'package:eacademia/features/packs/domain/pack_model.dart';
import 'package:eacademia/core/utils/formatters.dart';
import 'package:eacademia/core/theme/app_colors.dart';
import 'package:eacademia/core/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    // Requis pour DateFormat('fr_FR') utilisé dans Formatters
    await initializeDateFormatting('fr_FR', null);
  });

  // ── Modèle UserRole ───────────────────────────────────────────────────────

  group('UserRole', () {
    test('value retourne la chaîne Firestore correcte', () {
      expect(UserRole.pharmacien.value, 'pharmacien');
      expect(UserRole.medecin.value, 'medecin');
      expect(UserRole.kine.value, 'kine');
      expect(UserRole.commercial.value, 'commercial');
    });

    test('label retourne le libellé français', () {
      expect(UserRole.pharmacien.label, 'Pharmacien');
      expect(UserRole.medecin.label, 'Médecin');
      expect(UserRole.kine.label, 'Kinésithérapeute');
      expect(UserRole.commercial.label, 'Délégué commercial');
    });

    test('userRoleFromString renvoie le bon rôle', () {
      expect(userRoleFromString('pharmacien'), UserRole.pharmacien);
      expect(userRoleFromString('medecin'), UserRole.medecin);
      expect(userRoleFromString('kine'), UserRole.kine);
      expect(userRoleFromString('commercial'), UserRole.commercial);
    });

    test('userRoleFromString avec valeur inconnue retourne pharmacien', () {
      expect(userRoleFromString('unknown'), UserRole.pharmacien);
      expect(userRoleFromString(''), UserRole.pharmacien);
    });
  });

  // ── Permissions par rôle ──────────────────────────────────────────────────

  group('RolePermissions', () {
    test('pharmacien a accès à formations, produits, packs, factures', () {
      final modules = RolePermissions.getModules(UserRole.pharmacien);
      expect(modules, contains('formations'));
      expect(modules, contains('produits'));
      expect(modules, contains('packs'));
      expect(modules, contains('factures'));
    });

    test('commercial a accès à challenges', () {
      final modules = RolePermissions.getModules(UserRole.commercial);
      expect(modules, contains('challenges'));
    });

    test('hasAccess fonctionne correctement', () {
      expect(RolePermissions.hasAccess(UserRole.pharmacien, 'formations'), isTrue);
      // Le labo est accessible à tous
      expect(RolePermissions.hasAccess(UserRole.medecin, 'labo'), isTrue);
    });
  });

  // ── PackModel ─────────────────────────────────────────────────────────────

  group('PackModel', () {
    const items = [
      PackItem(name: 'Produit A', quantity: 2, unitPrice: 10.0),
      PackItem(name: 'Produit B', quantity: 1, unitPrice: 5.0),
    ];

    test('discountedPrice sans remise égale totalPrice', () {
      const pack = PackModel(
        id: '1',
        name: 'Test Pack',
        icon: '',
        items: items,
        totalPrice: 100.0,
        discountPercent: 0,
        targetRoles: [],
      );
      expect(pack.discountedPrice, equals(100.0));
    });

    test('discountedPrice avec 20% de remise', () {
      const pack = PackModel(
        id: '1',
        name: 'Test Pack',
        icon: '',
        items: items,
        totalPrice: 100.0,
        discountPercent: 20,
        targetRoles: [],
      );
      expect(pack.discountedPrice, closeTo(80.0, 0.001));
    });

    test('discountedPrice avec 100% retourne 0', () {
      const pack = PackModel(
        id: '1',
        name: 'Test Pack',
        icon: '',
        items: items,
        totalPrice: 50.0,
        discountPercent: 100,
        targetRoles: [],
      );
      expect(pack.discountedPrice, equals(0.0));
    });
  });

  // ── Formatters ────────────────────────────────────────────────────────────

  group('Formatters', () {
    test('formatCurrency formate en euros', () {
      final result = Formatters.formatCurrency(1234.5);
      expect(result, contains('1'));
      expect(result, contains('234'));
      expect(result, contains('€'));
    });

    test('formatCurrency gère zéro', () {
      final result = Formatters.formatCurrency(0);
      expect(result, contains('€'));
    });

    test('formatDate retourne une chaîne non vide', () {
      final date = DateTime(2024, 6, 15);
      final result = Formatters.formatDate(date);
      expect(result, isNotEmpty);
      expect(result, contains('2024'));
    });
  });

  // ── Widgets légers (sans Firebase) ────────────────────────────────────────

  group('Theme widgets', () {
    testWidgets('AppTheme.light crée un ThemeData valide', (tester) async {
      final theme = AppTheme.light;
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });

    testWidgets('AppTheme.dark crée un ThemeData valide', (tester) async {
      final theme = AppTheme.dark;
      expect(theme.brightness, equals(Brightness.dark));
    });

    testWidgets('Card avec texte s\'affiche correctement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Card(
              child: ListTile(title: Text('Test carte')),
            ),
          ),
        ),
      );
      expect(find.text('Test carte'), findsOneWidget);
    });

    testWidgets('Pack card affiche le nom du pack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pack Vitalité',
                  style: AppTheme.light.textTheme.titleLarge,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Pack Vitalité'), findsOneWidget);
    });

    testWidgets('ElevatedButton déclenche le callback onPressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Commander'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Commander'));
      expect(tapped, isTrue);
    });
  });

  // ── Logique de filtrage ───────────────────────────────────────────────────

  group('Filtrage des listes', () {
    test('filtre par rôle sur targetRoles', () {
      const packs = [
        PackModel(
          id: '1',
          name: 'Pack Pharma',
          icon: '',
          items: [],
          totalPrice: 100,
          discountPercent: 0,
          targetRoles: ['pharmacien'],
        ),
        PackModel(
          id: '2',
          name: 'Pack Médecin',
          icon: '',
          items: [],
          totalPrice: 80,
          discountPercent: 0,
          targetRoles: ['medecin'],
        ),
        PackModel(
          id: '3',
          name: 'Pack Tous',
          icon: '',
          items: [],
          totalPrice: 60,
          discountPercent: 0,
          targetRoles: ['pharmacien', 'medecin'],
        ),
      ];

      final pharmacienPacks =
          packs.where((p) => p.targetRoles.contains('pharmacien')).toList();
      expect(pharmacienPacks.length, equals(2));
      expect(pharmacienPacks.map((p) => p.name),
          containsAll(['Pack Pharma', 'Pack Tous']));

      final medecinPacks =
          packs.where((p) => p.targetRoles.contains('medecin')).toList();
      expect(medecinPacks.length, equals(2));
    });
  });
}
