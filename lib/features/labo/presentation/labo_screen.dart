import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

// Contenu par défaut si Firestore n'a pas de doc labo_content/main
const _defaultSections = [
  _LaboSectionData(
    icon: Icons.history,
    title: 'Notre Histoire',
    content:
        'Granions, laboratoire pharmaceutique français fondé en 1950, est spécialisé dans les oligoéléments et les compléments alimentaires. Notre expertise de plus de 70 ans nous permet de proposer des solutions naturelles de haute qualité aux professionnels de santé.',
  ),
  _LaboSectionData(
    icon: Icons.science_outlined,
    title: 'Recherche & Développement',
    content:
        'Notre laboratoire R&D collabore avec des instituts de recherche reconnus pour développer des formulations innovantes. Chaque produit est soumis à des études cliniques rigoureuses avant sa mise sur le marché.',
  ),
  _LaboSectionData(
    icon: Icons.verified_outlined,
    title: 'Certifications',
    content:
        'Granions est certifié BPF (Bonnes Pratiques de Fabrication), ISO 9001:2015 et dispose de l\'ensemble des accréditations réglementaires françaises et européennes.',
  ),
  _LaboSectionData(
    icon: Icons.eco_outlined,
    title: 'RSE — Engagement durable',
    content:
        'Notre politique RSE s\'articule autour de trois axes : réduction de l\'empreinte carbone, sourcing responsable de nos matières premières, et engagement dans des actions de santé communautaire.',
  ),
  _LaboSectionData(
    icon: Icons.contact_phone_outlined,
    title: 'Contact',
    content:
        'Service médical : medical@granions.fr\nDélégués régionaux : commercial@granions.fr\nSiège social : 75 Rue des Granions, 75001 Paris\nTél : +33 1 23 45 67 89',
  ),
];

class LaboScreen extends ConsumerWidget {
  const LaboScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Le Laboratoire')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(AppConstants.colLaboContent)
            .doc('main')
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LaboSkeleton();
          }

          // Si erreur ou doc inexistant → contenu par défaut
          final sections = _parseSections(snap.data);

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const _LaboHero(),
                const SizedBox(height: 24),
                ...sections.asMap().entries.map((e) => _LaboSection(
                      data: e.value,
                      isLast: e.key == sections.length - 1,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_LaboSectionData> _parseSections(DocumentSnapshot? doc) {
    if (doc == null || !doc.exists) return _defaultSections;

    final d = doc.data() as Map<String, dynamic>?;
    if (d == null) return _defaultSections;

    // Le document peut contenir un tableau "sections" ou des champs individuels
    if (d['sections'] is List) {
      final rawSections = d['sections'] as List;
      final parsed = rawSections
          .whereType<Map>()
          .map((s) => _LaboSectionData(
                icon: _iconFromString(s['icon'] as String? ?? ''),
                title: s['title'] as String? ?? '',
                content: s['content'] as String? ?? '',
              ))
          .where((s) => s.title.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }

    // Champs individuels (ex: history, rd, certifications…)
    final fieldMap = {
      'history': ('Notre Histoire', Icons.history),
      'rd': ('Recherche & Développement', Icons.science_outlined),
      'certifications': ('Certifications', Icons.verified_outlined),
      'rse': ('RSE — Engagement durable', Icons.eco_outlined),
      'contact': ('Contact', Icons.contact_phone_outlined),
    };

    final built = fieldMap.entries
        .where((e) => d[e.key] != null)
        .map((e) => _LaboSectionData(
              icon: e.value.$2,
              title: e.value.$1,
              content: d[e.key] as String,
            ))
        .toList();

    return built.isEmpty ? _defaultSections : built;
  }

  static IconData _iconFromString(String name) {
    return switch (name) {
      'history' => Icons.history,
      'science' => Icons.science_outlined,
      'verified' => Icons.verified_outlined,
      'eco' => Icons.eco_outlined,
      'contact' => Icons.contact_phone_outlined,
      'biotech' => Icons.biotech_outlined,
      _ => Icons.info_outline,
    };
  }
}

// ── Section data ──────────────────────────────────────────────────────────────

class _LaboSectionData {
  final IconData icon;
  final String title;
  final String content;

  const _LaboSectionData({
    required this.icon,
    required this.title,
    required this.content,
  });
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _LaboHero extends StatelessWidget {
  const _LaboHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.biotech,
                color: Colors.white.withValues(alpha: 0.1), size: 140),
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GRANIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Laboratoire pharmaceutique français',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section expandable ────────────────────────────────────────────────────────

class _LaboSection extends StatefulWidget {
  final _LaboSectionData data;
  final bool isLast;

  const _LaboSection({required this.data, required this.isLast});

  @override
  State<_LaboSection> createState() => _LaboSectionState();
}

class _LaboSectionState extends State<_LaboSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.data.icon,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.data.title,
                      style: theme.textTheme.titleLarge),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Text(widget.data.content, style: theme.textTheme.bodyMedium),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        if (!widget.isLast) ...[
          const Divider(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _LaboSkeleton extends StatelessWidget {
  const _LaboSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
            height: 160,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 24),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 20,
                    width: 160,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(
                    height: 14,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(
                    height: 14,
                    width: 240,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
