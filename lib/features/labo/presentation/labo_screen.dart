import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LaboScreen extends StatelessWidget {
  const LaboScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec hero ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _LaboHero(),
            ),
            title: const Text(
              'Le Laboratoire',
              style: TextStyle(color: Colors.white),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Chiffres clés ──────────────────────────────────────
                const _KeyFiguresSection(),

                // ── Notre histoire ─────────────────────────────────────
                _ContentSection(
                  icon: Icons.history_edu_outlined,
                  title: 'Notre Histoire',
                  child: _HistoryContent(),
                ),

                // ── Innovation & R&D ───────────────────────────────────
                _ContentSection(
                  icon: Icons.science_outlined,
                  title: 'Innovation & R&D',
                  child: _RDContent(),
                ),

                // ── Qualité & Fabrication ──────────────────────────────
                _ContentSection(
                  icon: Icons.verified_outlined,
                  title: 'Qualité & Fabrication',
                  child: _QualityContent(),
                ),

                // ── RSE & Développement durable ────────────────────────
                _ContentSection(
                  icon: Icons.eco_outlined,
                  title: 'Développement Durable',
                  child: _RSEContent(),
                ),

                // ── Équipe dirigeante ──────────────────────────────────
                _ContentSection(
                  icon: Icons.people_outline,
                  title: 'Équipe Dirigeante',
                  child: _TeamContent(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _LaboHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF1565C0), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Motif décoratif
          Positioned(
            right: -40,
            top: -40,
            child: Icon(Icons.biotech,
                size: 220, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Icon(Icons.science,
                size: 160, color: Colors.white.withValues(alpha: 0.05)),
          ),
          // Contenu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEPUIS 1948',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Granions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Laboratoire pharmaceutique français\npionnier de l\'oligothérapie',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'Mougins · Sophia Antipolis',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chiffres clés ─────────────────────────────────────────────────────────────

class _KeyFiguresSection extends StatelessWidget {
  const _KeyFiguresSection();

  static const _figures = [
    _Figure('1948', 'Fondé à\nParis'),
    _Figure('100+', 'Collabora-\nteurs'),
    _Figure('50+', 'Produits\n/ an'),
    _Figure('−26%', 'CO₂\n2022–23'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: _figures
            .map((f) => Expanded(child: _FigureTile(figure: f)))
            .toList(),
      ),
    );
  }
}

class _Figure {
  final String value;
  final String label;
  const _Figure(this.value, this.label);
}

class _FigureTile extends StatelessWidget {
  final _Figure figure;
  const _FigureTile({required this.figure});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            figure.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            figure.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section générique ─────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ContentSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

// ── Contenu Notre Histoire ─────────────────────────────────────────────────────

class _HistoryContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Quote(
          text:
              '« Le nom Granions vient de "grains d\'ions" — une référence directe à notre procédé unique où les oligoéléments sont solubilisés dans l\'eau, puis encapsulés dans de l\'amylose de pomme de terre, sans gluten. »',
        ),
        const SizedBox(height: 16),
        Text(
          'Fondé en 1948 dans une pharmacie parisienne, Granions est aujourd\'hui l\'un des laboratoires pharmaceutiques français les plus reconnus dans le domaine des compléments nutritionnels et de l\'oligothérapie.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 12),
        Text(
          'Depuis son origine, Granions a développé une approche pionnière : offrir des solutions de santé naturelles, efficaces et sûres, fondées sur la rigueur scientifique et les standards pharmaceutiques.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 16),
        _TimelineItem(year: '1948', label: 'Fondation dans une pharmacie parisienne'),
        _TimelineItem(year: '1970s', label: 'Leader de l\'oligothérapie en France'),
        _TimelineItem(year: '2000s', label: 'Installation à Mougins, Sophia Antipolis'),
        _TimelineItem(year: 'Aujourd\'hui', label: '100+ collaborateurs, présence nationale'),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  final String text;
  const _Quote({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String year;
  final String label;
  const _TimelineItem({required this.year, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              year,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contenu R&D ───────────────────────────────────────────────────────────────

class _RDContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Granions développe plus de 50 nouveaux produits par an, couvrant des domaines variés : stress, sommeil, énergie, immunité, articulations, muscles, beauté et dermatologie.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Stress & Sommeil',
            'Énergie',
            'Immunité',
            'Articulations',
            'Muscles',
            'Beauté',
            'Dermatologie',
            'Oligoéléments',
          ]
              .map((cat) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'La gamme comprend des compléments alimentaires, dispositifs médicaux et médicaments — tous soumis à des études cliniques rigoureuses avant commercialisation.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

// ── Contenu Qualité ───────────────────────────────────────────────────────────

class _QualityContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QualityPoint(
          icon: Icons.factory_outlined,
          title: 'Site de production',
          subtitle: 'Annemasse (Haute-Savoie) — aux normes BPF',
        ),
        _QualityPoint(
          icon: Icons.track_changes_outlined,
          title: 'Traçabilité complète',
          subtitle: 'De la matière première jusqu\'au produit fini',
        ),
        _QualityPoint(
          icon: Icons.info_outline,
          title: 'Transparence totale',
          subtitle: 'Composition, dosages, allergènes détaillés sur chaque produit',
        ),
        _QualityPoint(
          icon: Icons.gavel_outlined,
          title: 'Conformité réglementaire',
          subtitle: 'Accréditations françaises et européennes en vigueur',
        ),
      ],
    );
  }
}

class _QualityPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _QualityPoint(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contenu RSE ───────────────────────────────────────────────────────────────

class _RSEContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sur la période 2022–2023, Granions a engagé une démarche RSE ambitieuse avec des résultats mesurables :',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RSEMetric(
                icon: Icons.co2_outlined,
                color: AppColors.success,
                value: '−26%',
                label: 'Émissions\nde CO₂',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RSEMetric(
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF0288D1),
                value: '−12%',
                label: 'Eau\n/ unité',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RSEMetric(
                icon: Icons.recycling_outlined,
                color: const Color(0xFF43A047),
                value: '100%',
                label: 'Emballages\nrecyclables',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RSEMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _RSEMetric(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}

// ── Contenu Équipe ────────────────────────────────────────────────────────────

class _TeamContent extends StatelessWidget {
  static const _members = [
    _TeamMember('Jean-Noël Perrin', 'Directeur Pharmaceutique', 'JP'),
    _TeamMember('Estelle Prévost', 'Directrice R&D', 'EP'),
    _TeamMember('Emmanuel Gouillard', 'Responsable Qualité & Logistique', 'EG'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _members.map((m) => _TeamCard(member: m)).toList(),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String initials;
  const _TeamMember(this.name, this.role, this.initials);
}

class _TeamCard extends StatelessWidget {
  final _TeamMember member;
  const _TeamCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              member.initials,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(member.role, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
