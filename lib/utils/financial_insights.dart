import 'package:flutter/material.dart';

import '../models/category_budget.dart';
import '../models/transaction.dart';
import 'recurrence_normalization.dart';
import 'transaction_subtype_helpers.dart';

/// Lightweight insight surfaced on the dashboard. Future AI-generated
/// insights can implement the same shape so the UI doesn't need to change.
enum InsightTone { neutral, positive, warning, danger }

class FinancialInsight {
  const FinancialInsight({
    required this.id,
    required this.message,
    required this.icon,
    this.tone = InsightTone.neutral,
    this.actionLabel,
    this.actionPayload,
  });

  final String id;
  final String message;
  final IconData icon;
  final InsightTone tone;
  final String? actionLabel;

  /// Opaque payload returned to the host when the action chip is tapped. The
  /// dashboard maps known payload strings to navigation intents (e.g.
  /// `'filter:Subscription'` switches the transactions tab to that filter).
  final String? actionPayload;
}

/// Pure function — same input always returns the same insights. Swap with an
/// AI-driven generator later by matching this signature.
typedef InsightGenerator = List<FinancialInsight> Function({
  required List<Transaction> transactions,
  required List<CategoryBudget> budgets,
  DateTime? now,
});

/// Rule-based heuristics. Limited to short, conversational copy.
List<FinancialInsight> generateInsights({
  required List<Transaction> transactions,
  required List<CategoryBudget> budgets,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final results = <FinancialInsight>[];

  _categoryDelta(results, transactions, clock);
  _weekendSkew(results, transactions, clock);
  _subscriptionsCost(results, transactions);
  _budgetProximity(results, transactions, budgets, clock);

  return results;
}

void _categoryDelta(
  List<FinancialInsight> out,
  List<Transaction> transactions,
  DateTime now,
) {
  final thisMonth = DateTime(now.year, now.month);
  final lastMonth = DateTime(now.year, now.month - 1);

  final thisTotals = <String, double>{};
  final lastTotals = <String, double>{};
  for (final tx in transactions) {
    if (!tx.isExpense) continue;
    final cat = (tx.category ?? 'Other');
    final ym = DateTime(tx.date.year, tx.date.month);
    if (ym == thisMonth) {
      thisTotals[cat] = (thisTotals[cat] ?? 0) + tx.amount;
    } else if (ym == lastMonth) {
      lastTotals[cat] = (lastTotals[cat] ?? 0) + tx.amount;
    }
  }

  String? bumpedCategory;
  double bumpedDelta = 0;
  thisTotals.forEach((cat, amount) {
    final prior = lastTotals[cat] ?? 0;
    if (prior <= 0) return;
    final delta = (amount - prior) / prior;
    if (delta > bumpedDelta) {
      bumpedDelta = delta;
      bumpedCategory = cat;
    }
  });

  if (bumpedCategory != null && bumpedDelta >= 0.15) {
    final pct = (bumpedDelta * 100).round();
    out.add(
      FinancialInsight(
        id: 'category-delta-$bumpedCategory',
        message:
            '$bumpedCategory spending up $pct% vs last month — worth a glance.',
        icon: Icons.trending_up_rounded,
        tone: bumpedDelta >= 0.35 ? InsightTone.warning : InsightTone.neutral,
        actionLabel: 'See category',
        actionPayload: 'filter:category:$bumpedCategory',
      ),
    );
  }
}

void _weekendSkew(
  List<FinancialInsight> out,
  List<Transaction> transactions,
  DateTime now,
) {
  final monthStart = DateTime(now.year, now.month);
  double weekend = 0;
  double weekday = 0;
  for (final tx in transactions) {
    if (!tx.isExpense) continue;
    if (tx.date.isBefore(monthStart)) continue;
    if (tx.date.weekday >= DateTime.saturday) {
      weekend += tx.amount;
    } else {
      weekday += tx.amount;
    }
  }
  if (weekend <= 0 || weekday <= 0) return;
  final weekendPerDay = weekend / 8.0;
  final weekdayPerDay = weekday / 22.0;
  if (weekendPerDay > weekdayPerDay * 1.4) {
    out.add(
      const FinancialInsight(
        id: 'weekend-skew',
        message: 'Weekend spending is your highest — most goes out Sat & Sun.',
        icon: Icons.weekend_rounded,
        tone: InsightTone.neutral,
      ),
    );
  }
}

void _subscriptionsCost(
  List<FinancialInsight> out,
  List<Transaction> transactions,
) {
  double monthly = 0;
  var count = 0;
  for (final tx in transactions) {
    if (!tx.isExpense || !tx.isRecurring) continue;
    if (!TransactionSubtypeHelpers.isSubscriptionCategory(tx.category)) {
      continue;
    }
    monthly += monthlyEquivalent(tx);
    count++;
  }
  if (count == 0 || monthly <= 0) return;
  out.add(
    FinancialInsight(
      id: 'subscriptions',
      message:
          'Your $count subscriptions cost about ${_compact(monthly)} a month.',
      icon: Icons.subscriptions_rounded,
      tone: InsightTone.neutral,
      actionLabel: 'Review',
      actionPayload: 'filter:type:subscription',
    ),
  );
}

void _budgetProximity(
  List<FinancialInsight> out,
  List<Transaction> transactions,
  List<CategoryBudget> budgets,
  DateTime now,
) {
  if (budgets.isEmpty) return;
  final monthStart = DateTime(now.year, now.month);

  for (final budget in budgets) {
    final spent = transactions
        .where(
          (t) =>
              t.isExpense &&
              !t.date.isBefore(monthStart) &&
              (t.category ?? '').toLowerCase() ==
                  budget.categoryName.toLowerCase(),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
    if (budget.monthlyLimit <= 0) continue;
    final ratio = spent / budget.monthlyLimit;
    if (ratio >= 1) {
      out.add(
        FinancialInsight(
          id: 'budget-over-${budget.categoryName}',
          message:
              'You\'ve gone past your ${budget.categoryName} budget this month.',
          icon: Icons.warning_amber_rounded,
          tone: InsightTone.danger,
          actionLabel: 'Adjust',
          actionPayload: 'budget:${budget.categoryName}',
        ),
      );
      return;
    }
    if (ratio >= 0.85) {
      out.add(
        FinancialInsight(
          id: 'budget-near-${budget.categoryName}',
          message:
              'You\'re close to your ${budget.categoryName} budget for the month.',
          icon: Icons.speed_rounded,
          tone: InsightTone.warning,
          actionLabel: 'See budget',
          actionPayload: 'budget:${budget.categoryName}',
        ),
      );
      return;
    }
  }
}


String _compact(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}
