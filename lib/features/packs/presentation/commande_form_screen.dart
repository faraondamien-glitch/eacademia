import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/packs_repository.dart';
import '../domain/pack_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class CommandeFormScreen extends ConsumerStatefulWidget {
  final String packId;
  const CommandeFormScreen({super.key, required this.packId});

  @override
  ConsumerState<CommandeFormScreen> createState() => _CommandeFormScreenState();
}

class _CommandeFormScreenState extends ConsumerState<CommandeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  PackModel? _pack;
  bool _isLoadingPack = true;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPack();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPack() async {
    final repo = ref.read(packsRepositoryProvider);
    final pack = await repo.getPack(widget.packId);
    if (mounted) {
      setState(() {
        _pack = pack;
        _isLoadingPack = false;
      });
    }
  }

  double get _runningTotal => (_pack?.discountedPrice ?? 0) * _quantity;

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pack == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_pack!.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantité : $_quantity'),
                Text(
                  Formatters.formatCurrency(_runningTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (_commentController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note : ${_commentController.text.trim()}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(userProvider);
      final repo = ref.read(packsRepositoryProvider);
      await repo.placeOrder(
        userId: user?.uid ?? '',
        packId: widget.packId,
        packName: _pack!.name,
        quantity: _quantity,
        comment: _commentController.text.trim(),
        totalAmount: _runningTotal,
      );
      if (!mounted) return;
      // Retourne à l'écran pack et affiche la confirmation
      context.pop();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Commande envoyée — ${_pack!.name}')),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'envoi : ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pack?.name ?? 'Commander'),
      ),
      body: _isLoadingPack
          ? const Center(child: CircularProgressIndicator())
          : _pack == null
              ? const Center(child: Text('Pack introuvable'))
              : _buildForm(context),
      bottomNavigationBar: _isLoadingPack || _pack == null
          ? null
          : _SubmitBar(
              total: _runningTotal,
              isSubmitting: _isSubmitting,
              onSubmit: _confirmAndSubmit,
            ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final pack = _pack!;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Résumé du pack
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.name, style: theme.textTheme.titleMedium),
                        Text(
                          '${pack.items.length} produit${pack.items.length > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(pack.discountedPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quantité
          Text('Quantité', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _quantity > 1 ? AppColors.primary : null,
                    iconSize: 32,
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_quantity',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _quantity > 1 ? 'packs' : 'pack',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    iconSize: 32,
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Total en temps réel
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total estimé',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_quantity × ${Formatters.formatCurrency(pack.discountedPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatCurrency(_runningTotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Commentaire
          Text('Commentaire', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText:
                  'Précisions, adresse de livraison, délai souhaité…',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de validation ───────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final double total;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.total,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmer — ${Formatters.formatCurrency(total)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
