import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/facture_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class FactureItem extends StatelessWidget {
  final FactureModel facture;
  const FactureItem({super.key, required this.facture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = facture.status == FactureStatus.paid;
    final statusColor = isPaid ? AppColors.success : AppColors.warning;
    final hasPdf = facture.pdfUrl.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasPdf
            ? () => context.push(
                  '/pdf-viewer',
                  extra: {
                    'url': facture.pdfUrl,
                    'title': facture.reference,
                  },
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icône statut
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.schedule_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Référence + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facture.reference, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatDate(facture.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Montant + badge statut
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(facture.amount),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid ? 'Payée' : 'En attente',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              if (hasPdf) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
