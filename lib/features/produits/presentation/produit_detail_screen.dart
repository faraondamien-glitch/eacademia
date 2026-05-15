import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../data/produits_repository.dart';
import '../domain/produit_model.dart';
import '../../../core/theme/app_colors.dart';
import 'pdf_viewer_screen.dart';

class ProduitDetailScreen extends ConsumerWidget {
  final String produitId;
  const ProduitDetailScreen({super.key, required this.produitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(produitsRepositoryProvider);

    return FutureBuilder<ProduitModel?>(
      future: repo.getProduit(produitId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final produit = snap.data;
        if (produit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Produit introuvable')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // AppBar avec image produit
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                title: Text(produit.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Partager',
                    onPressed: () => Share.share(
                      '${produit.name} — ${produit.range}\n\nGranions EACADEMIA',
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProductHero(produit: produit),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Badge gamme
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          produit.range,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags
                    if (produit.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: produit.tags
                            .map((t) => Chip(
                                  label: Text(t),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Sections de contenu
                    _InfoSection(
                      icon: Icons.info_outline,
                      title: 'Description',
                      content: produit.description,
                    ),
                    _InfoSection(
                      icon: Icons.science_outlined,
                      title: 'Composition',
                      content: produit.composition,
                    ),
                    _InfoSection(
                      icon: Icons.check_circle_outline,
                      title: 'Indications',
                      content: produit.indications,
                      accentColor: AppColors.success,
                    ),
                    _InfoSection(
                      icon: Icons.warning_amber_outlined,
                      title: 'Contre-indications',
                      content: produit.contraindications,
                      accentColor: AppColors.warning,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Bouton PDF flottant
          bottomNavigationBar: _PdfBottomBar(produit: produit),
        );
      },
    );
  }
}

// ── Hero produit ──────────────────────────────────────────────────────────────

class _ProductHero extends StatelessWidget {
  final ProduitModel produit;
  const _ProductHero({required this.produit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Image ou placeholder
          if (produit.thumbnailUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: produit.thumbnailUrl,
                fit: BoxFit.contain,
                errorWidget: (_, e, s) => _PlaceholderIcon(),
              ),
            )
          else
            Positioned.fill(child: _PlaceholderIcon()),

          // Dégradé bas pour lisibilité du titre
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.medication_outlined,
        size: 96,
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

// ── Section de contenu ────────────────────────────────────────────────────────

class _InfoSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color? accentColor;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    this.accentColor,
  });

  @override
  State<_InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends State<_InfoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) return const SizedBox.shrink();
    final accent = widget.accentColor ?? AppColors.primary;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Column(
          children: [
            // En-tête cliquable (expand/collapse)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Contenu (animé)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      widget.content,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barre PDF bas de page ─────────────────────────────────────────────────────

class _PdfBottomBar extends StatelessWidget {
  final ProduitModel produit;
  const _PdfBottomBar({required this.produit});

  @override
  Widget build(BuildContext context) {
    final hasPdf = produit.fichePdfUrl.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton PDF principal
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasPdf
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            url: produit.fichePdfUrl,
                            title: '${produit.name} — Fiche produit',
                          ),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(hasPdf ? 'Voir la fiche PDF' : 'PDF non disponible'),
            ),
          ),

          // Bouton partager séparé (si PDF)
          if (hasPdf) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Share.share(
                '${produit.name} — ${produit.range}\n${produit.fichePdfUrl}',
                subject: produit.name,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.share_outlined),
            ),
          ],
        ],
      ),
    );
  }
}
