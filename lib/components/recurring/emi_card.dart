import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import 'upcoming_timeline_section.dart';

/// EMI-specific card with a progress strip ("8/24 months · ₹1,20,000 left").
///
/// EMIs share the subscription card's overall vibe but lean on the warning
/// tone (because EMIs feel different than discretionary subscriptions) and
/// surface a progress bar driven by [RecurringManagement.emiProgress].
class EmiCard extends StatelessWidget {
  const EmiCard({
    super.key,
    required this.item,
    required this.progress,
    required this.onTap,
    required this.onAction,
  });

  final RecurringScheduleItem item;
  final EmiProgress? progress;
  final VoidCallback onTap;
  final void Function(RecurringQuickAction action) onAction;

  String? get _dueLabel {
    final next = item.nextDueDate;
    if (next == null) return null;
    return DateFormat.MMMd().format(next);
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final tone = AppColors.warning;
    final dueLabel = _dueLabel;
    final paused = item.isPaused;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: paused ? AppColors.border : tone.withAlpha(72),
              width: paused ? 1 : 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.withAlpha(paused ? 24 : 36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: tone,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.transaction.counterpartyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currency.format(item.transaction.amount)} '
                          '· monthly',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  _EmiOverflowMenu(onSelect: onAction, isPaused: paused),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.account_balance_rounded,
                      label: item.account?.name ?? 'No account linked',
                    ),
                  ),
                  if (dueLabel != null)
                    _MetaLine(
                      icon: Icons.event_rounded,
                      label: paused ? 'Paused' : 'Due $dueLabel',
                      tone: paused ? AppColors.textSecondary : tone,
                    ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ProgressStrip(progress: progress!, tone: tone, paused: paused),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.progress,
    required this.tone,
    required this.paused,
  });

  final EmiProgress progress;
  final Color tone;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${progress.completed}/${progress.total} months',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${currency.formatCompact(progress.remainingPrincipal)} '
              'remaining',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.completionRatio,
            minHeight: 6,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              paused ? AppColors.textSecondary : tone,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: tone ?? AppColors.textSecondary,
              fontWeight: tone != null ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmiOverflowMenu extends StatelessWidget {
  const _EmiOverflowMenu({required this.onSelect, required this.isPaused});

  final void Function(RecurringQuickAction action) onSelect;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecurringQuickAction>(
      tooltip: 'More actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surfaceSecondary,
      onSelected: onSelect,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: RecurringQuickAction.markPaid,
          child: _EmiMenuRow(
            icon: Icons.check_circle_rounded,
            label: 'Mark paid',
          ),
        ),
        const PopupMenuItem(
          value: RecurringQuickAction.snooze,
          child: _EmiMenuRow(
            icon: Icons.snooze_rounded,
            label: 'Snooze 3 days',
          ),
        ),
        PopupMenuItem(
          value: RecurringQuickAction.pause,
          child: _EmiMenuRow(
            icon: isPaused
                ? Icons.play_circle_rounded
                : Icons.pause_circle_rounded,
            label: isPaused ? 'Resume reminders' : 'Pause reminders',
          ),
        ),
        const PopupMenuItem(
          value: RecurringQuickAction.close,
          // "Completed" is the right verb for EMIs — loans don't get
          // cancelled the way subscriptions do.
          child: _EmiMenuRow(
            icon: Icons.task_alt_rounded,
            label: 'Mark as completed',
            tone: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _EmiMenuRow extends StatelessWidget {
  const _EmiMenuRow({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;

  /// Optional override colour for destructive actions (Mark as completed).
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
