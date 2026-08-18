import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/common/states/loading_state.dart';
import '../../components/recurring/active_subscriptions_section.dart';
import '../../components/recurring/add_recurring_sheet.dart';
import '../../components/recurring/emi_management_section.dart';
import '../../components/recurring/payment_insights_section.dart';
import '../../components/recurring/recurring_empty_state.dart';
import '../../components/recurring/recurring_expenses_section.dart';
import '../../components/recurring/recurring_header.dart';
import '../../components/recurring/upcoming_timeline_section.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';
import '../../services/supabase_service.dart';
import '../../utils/recurring_management.dart';
import '../../utils/snackbar_helper.dart';

/// Full-screen Recurring Payments / EMI / Subscription manager.
///
/// Hosted as a pushed route from the Analytics "Subscriptions & Recurring"
/// card's "View all" link. The page is self-sufficient:
///
/// * It receives an initial snapshot of `transactions` and `accounts` from
///   the parent (which has them in memory).
/// * It owns the per-occurrence `_events` state and re-fetches both the
///   transactions and events after every mutation so the timeline stays
///   in sync without needing the parent to push updates.
/// * Quick actions (Mark paid / Skip / Snooze / Pause) call SupabaseService
///   directly and notify the parent via [onMutation] so its caches refresh
///   when the user pops back.
///
/// Performance: aggregations happen once per build via
/// [RecurringManagement.build]; every section is stateless and reads from
/// the already-derived snapshot.
class RecurringPaymentsPage extends StatefulWidget {
  const RecurringPaymentsPage({
    super.key,
    required this.initialTransactions,
    required this.accounts,
    this.monthlyIncome,
    required this.onTapTransaction,
    required this.onAddRecurring,
    required this.onMutation,
  });

  final List<Transaction> initialTransactions;
  final List<Account> accounts;

  /// Used by [PaymentInsightsSection] to compute the "EMIs consume X% of
  /// monthly income" line. Null hides that insight.
  final double? monthlyIncome;

  /// Opens the existing transaction detail sheet for an item. The parent
  /// owns the edit / duplicate / delete flows that the sheet routes to.
  final void Function(Transaction transaction) onTapTransaction;

  /// User picked a kind from the add sheet — parent preconfigures a
  /// `TransactionDraft` via `applyDraftFor` and pushes the
  /// AddTransactionPage. Awaits parent completion so we can refresh once
  /// the user comes back.
  final Future<void> Function(RecurringKind kind) onAddRecurring;

  /// Called whenever this page mutates Supabase so the parent's home/
  /// analytics caches stay in sync. The page also calls its own refresh
  /// independently to keep its UI live.
  final Future<void> Function() onMutation;

  @override
  State<RecurringPaymentsPage> createState() => _RecurringPaymentsPageState();
}

class _RecurringPaymentsPageState extends State<RecurringPaymentsPage> {
  late List<Transaction> _transactions;
  List<RecurringEvent> _events = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transactions = List<Transaction>.from(widget.initialTransactions);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final events = await SupabaseService.fetchRecurringEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, error);
    }
  }

  Future<void> _refreshAll() async {
    try {
      final results = await Future.wait([
        SupabaseService.fetchTransactions(),
        SupabaseService.fetchRecurringEvents(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _events = results[1] as List<RecurringEvent>;
      });
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  // ---- action handlers ----------------------------------------------------

  Future<void> _handleAction(
    RecurringQuickAction action,
    Transaction transaction,
    DateTime occurrenceDate,
  ) async {
    switch (action) {
      case RecurringQuickAction.markPaid:
        await _markPaid(transaction, occurrenceDate);
        break;
      case RecurringQuickAction.skip:
        await _logEvent(
          transaction,
          occurrenceDate,
          RecurringEventType.skipped,
          successMessage: 'Skipped next ${transaction.counterpartyName}',
        );
        break;
      case RecurringQuickAction.snooze:
        await _logEvent(
          transaction,
          occurrenceDate,
          RecurringEventType.snoozed,
          snoozeUntil: occurrenceDate.add(const Duration(days: 3)),
          successMessage: 'Snoozed ${transaction.counterpartyName} 3 days',
        );
        break;
      case RecurringQuickAction.pause:
        await _togglePause(transaction);
        break;
      case RecurringQuickAction.close:
        await _closeSchedule(transaction);
        break;
    }
  }

  Future<void> _markPaid(
    Transaction transaction,
    DateTime occurrenceDate,
  ) async {
    if (transaction.id == null) {
      SnackbarHelper.showWarning(
        context,
        'Save the transaction first before marking it paid.',
      );
      return;
    }

    try {
      // 1. Insert a one-time clone for the occurrence the user is closing
      //    out — preserves the recurring template for future occurrences.
      final clone = transaction.copyWith(
        id: null,
        date: DateTime.now(),
        isRecurring: false,
        isPaused: false,
        recurrenceFrequency: null,
        recurrenceStartDate: null,
        recurrenceEndDate: null,
        reminderTiming: null,
      );
      final insertedTx = await SupabaseService.insertTransaction(clone);

      // 2. Record the per-occurrence "paid" event so the timeline skips this
      //    date next time it iterates the schedule.
      final event = await SupabaseService.insertRecurringEvent(
        RecurringEvent(
          transactionId: transaction.id!,
          occurrenceDate: occurrenceDate,
          eventType: RecurringEventType.paid,
        ),
      );

      if (!mounted) return;

      await _refreshAll();
      unawaitedRefresh();

      // Best-effort undo trail: deleting either row independently keeps the
      // user in a consistent state because the next refresh re-derives.
      _scheduleUndo(
        message: 'Marked ${transaction.counterpartyName} as paid',
        undoLabel: 'Undo',
        onUndo: () async {
          try {
            await SupabaseService.deleteRecurringEvent(event.id!);
            if (insertedTx.id != null) {
              await SupabaseService.deleteTransaction(insertedTx.id!);
            }
            await _refreshAll();
            unawaitedRefresh();
          } catch (e) {
            if (mounted) SnackbarHelper.showError(context, e);
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  Future<void> _logEvent(
    Transaction transaction,
    DateTime occurrenceDate,
    RecurringEventType type, {
    DateTime? snoozeUntil,
    required String successMessage,
  }) async {
    if (transaction.id == null) {
      SnackbarHelper.showWarning(
        context,
        'Save the transaction first before scheduling actions on it.',
      );
      return;
    }
    try {
      final event = await SupabaseService.insertRecurringEvent(
        RecurringEvent(
          transactionId: transaction.id!,
          occurrenceDate: occurrenceDate,
          eventType: type,
          snoozeUntil: snoozeUntil,
        ),
      );
      if (!mounted) return;
      await _refreshAll();
      unawaitedRefresh();
      _scheduleUndo(
        message: successMessage,
        undoLabel: 'Undo',
        onUndo: () async {
          try {
            await SupabaseService.deleteRecurringEvent(event.id!);
            await _refreshAll();
            unawaitedRefresh();
          } catch (e) {
            if (mounted) SnackbarHelper.showError(context, e);
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  Future<void> _togglePause(Transaction transaction) async {
    if (transaction.id == null) return;
    final paused = !transaction.isPaused;
    try {
      await SupabaseService.setTransactionPaused(transaction.id!, paused);
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        paused
            ? 'Paused ${transaction.counterpartyName}'
            : 'Resumed ${transaction.counterpartyName}',
      );
      await _refreshAll();
      unawaitedRefresh();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  /// Permanently terminate a recurring schedule (cancel subscription, mark
  /// EMI completed, close a recurring expense).
  ///
  /// Flow:
  /// 1. Show a kind-aware confirmation dialog (subscriptions get the
  ///    cancellation language; EMIs get "Mark as completed"; everything else
  ///    gets a neutral "Close schedule" copy).
  /// 2. Stamp `transactions.closed_at = now()` via
  ///    [SupabaseService.setTransactionClosed]. The
  ///    [RecurringManagement.build] aggregation drops closed rows entirely,
  ///    so the card and its upcoming entry disappear on the next rebuild.
  /// 3. Offer a 4-second Undo snackbar that clears `closed_at` back to NULL
  ///    if the user changed their mind.
  Future<void> _closeSchedule(Transaction transaction) async {
    if (transaction.id == null) return;

    final kind = RecurringManagement.classify(transaction);
    final copy = _closeCopyFor(kind, transaction.counterpartyName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
          title: Text(copy.title, style: AppTextStyles.headingSmall),
          content: Text(copy.body, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.confirmLabel),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await SupabaseService.setTransactionClosed(
        transaction.id!,
        closed: true,
      );
      if (!mounted) return;
      await _refreshAll();
      unawaitedRefresh();

      _scheduleUndo(
        message: copy.successMessage,
        undoLabel: 'Undo',
        onUndo: () async {
          try {
            await SupabaseService.setTransactionClosed(
              transaction.id!,
              closed: false,
            );
            await _refreshAll();
            unawaitedRefresh();
          } catch (e) {
            if (mounted) SnackbarHelper.showError(context, e);
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  /// Build the dialog + snackbar copy for closing a schedule. Centralised
  /// so the page body stays terse and the verbs stay consistent if we add
  /// more entry points in the future.
  _CloseCopy _closeCopyFor(RecurringKind kind, String name) {
    switch (kind) {
      case RecurringKind.subscription:
        return _CloseCopy(
          title: 'Cancel $name?',
          body:
              'We\'ll stop tracking future renewals. You can re-add it later '
              'if you sign back up.',
          confirmLabel: 'Cancel subscription',
          successMessage: 'Cancelled $name',
        );
      case RecurringKind.emi:
        return _CloseCopy(
          title: 'Mark $name as completed?',
          body:
              'No more EMI reminders will fire. Use this when the loan is '
              'fully paid off.',
          confirmLabel: 'Mark completed',
          successMessage: 'Marked $name as completed',
        );
      case RecurringKind.other:
        return _CloseCopy(
          title: 'Close $name?',
          body:
              'Future occurrences won\'t be tracked. You can add a new '
              'schedule later if it starts up again.',
          confirmLabel: 'Close schedule',
          successMessage: 'Closed $name',
        );
    }
  }

  /// Fire-and-forget call to the parent's refresh so its in-memory caches
  /// pick up our changes too. Wrapped in its own helper because we do it
  /// after every mutation but don't want to block the UI for it.
  void unawaitedRefresh() {
    // Intentionally not awaited — the page already updated locally.
    widget.onMutation();
  }

  void _scheduleUndo({
    required String message,
    required String undoLabel,
    required Future<void> Function() onUndo,
  }) {
    SnackbarHelper.showWithUndo(
      context,
      message: message,
      undoLabel: undoLabel,
      onUndo: () => onUndo(),
    );
  }

  // ---- add flow -----------------------------------------------------------

  Future<void> _onAddPressed() async {
    final choice = await showAddRecurringSheet(context);
    if (choice == null || !mounted) return;
    await widget.onAddRecurring(choice);
    if (!mounted) return;
    await _refreshAll();
  }

  // ---- detail tap ---------------------------------------------------------

  void _onTapTransaction(Transaction transaction) {
    // The parent owns the edit/duplicate/delete pipeline, so we delegate.
    // After the detail sheet closes the user might have edited the schedule
    // (e.g. changed end date) — refresh once they're back.
    widget.onTapTransaction(transaction);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _refreshAll();
    });
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final snapshot = RecurringManagement.build(
      transactions: _transactions,
      events: _events,
      accounts: widget.accounts,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Recurring',
          style: AppTextStyles.headingSmall,
        ),
      ),
      floatingActionButton: snapshot.isEmpty && !_isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _onAddPressed,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primarySoft,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const LoadingState()
            : RefreshIndicator(
                onRefresh: _refreshAll,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: snapshot.isEmpty
                    ? _buildEmpty()
                    : _buildScroll(snapshot),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: RecurringEmptyState(onAddRecurring: _onAddPressed),
          ),
        ),
      ],
    );
  }

  Widget _buildScroll(RecurringManagementSnapshot snapshot) {
    final monthLabel = DateFormat.MMMM().format(DateTime.now());

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            // Leave headroom for the floating "+" so the last section is
            // never obscured.
            AppSpacing.xxxl * 2,
          ),
          sliver: SliverList.list(
            children: [
              RecurringHeader(snapshot: snapshot, monthLabel: monthLabel),
              const SizedBox(height: AppSpacing.xxl),
              UpcomingTimelineSection(
                snapshot: snapshot,
                onTapItem: (item) => _onTapTransaction(item.transaction),
                onAction: (action, item) =>
                    _handleAction(action, item.transaction, item.dueDate),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ActiveSubscriptionsSection(
                items: snapshot.subscriptions,
                monthlyTotal: snapshot.subscriptionsMonthly,
                onTapItem: (item) => _onTapTransaction(item.transaction),
                onAction: (action, item) => _handleAction(
                  action,
                  item.transaction,
                  item.nextDueDate ?? DateTime.now(),
                ),
                onAddSubscription: () =>
                    widget.onAddRecurring(RecurringKind.subscription)
                        .then((_) {
                  if (mounted) _refreshAll();
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              EmiManagementSection(
                items: snapshot.emis,
                monthlyTotal: snapshot.emisMonthly,
                onTapItem: (item) => _onTapTransaction(item.transaction),
                onAction: (action, item) => _handleAction(
                  action,
                  item.transaction,
                  item.nextDueDate ?? DateTime.now(),
                ),
                onAddEmi: () =>
                    widget.onAddRecurring(RecurringKind.emi).then((_) {
                  if (mounted) _refreshAll();
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              RecurringExpensesSection(
                items: snapshot.other,
                monthlyTotal: snapshot.otherMonthly,
                onTapItem: (item) => _onTapTransaction(item.transaction),
                onAction: (action, item) => _handleAction(
                  action,
                  item.transaction,
                  item.nextDueDate ?? DateTime.now(),
                ),
                onAddRecurringExpense: () =>
                    widget.onAddRecurring(RecurringKind.other).then((_) {
                  if (mounted) _refreshAll();
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PaymentInsightsSection(
                snapshot: snapshot,
                monthlyIncome: widget.monthlyIncome,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bundle of UI strings shown when terminating a recurring schedule.
/// Kept as a tiny value-object so `_closeCopyFor` can return all the
/// pieces (dialog title + body + confirm label + post-close snackbar) in
/// one shot without juggling positional records.
class _CloseCopy {
  const _CloseCopy({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.successMessage,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String successMessage;
}

