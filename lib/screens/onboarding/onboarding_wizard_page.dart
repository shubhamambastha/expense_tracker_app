import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/common/states/states.dart';
import '../../components/dialogs/add_account_dialog.dart';
import '../../components/onboarding/onboarding_accounts_step.dart';
import '../../components/onboarding/onboarding_budget_step.dart';
import '../../components/onboarding/onboarding_currency_step.dart';
import '../../components/onboarding/onboarding_income_intro_step.dart';
import '../../components/onboarding/onboarding_name_step.dart';
import '../../components/onboarding/onboarding_progress_header.dart';
import '../../components/onboarding/onboarding_recurring_intro_step.dart';
import '../../components/recurring/add_recurring_sheet.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart' show AccountType;
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../services/onboarding_analytics.dart';
import '../../services/onboarding_wizard_status.dart';
import '../../services/supabase_service.dart';
import '../../utils/income_flow_helpers.dart';
import '../../utils/recurring_management.dart' show RecurringKind;
import '../transaction/add_transaction_page.dart';

/// Post-login onboarding wizard: name → currency → budget → accounts →
/// income → recurring, then the dashboard. All 6 steps live in one inline
/// [PageView]; the recurring step's "Add" button pushes
/// [AddTransactionPage] on a nested [Navigator] scoped below the
/// persistent progress header, so the header stays visible across both
/// halves (design-review 7A/T10) and the PageView page underneath is still
/// there when the pushed route pops. Accounts run before income/recurring
/// so those steps have a real account to attach a transaction to, instead
/// of silently dropping data when none exists.
class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

const _stepCount = 6;
const _stepIds = [
  'name',
  'currency',
  'budget',
  'accounts',
  'income',
  'recurring',
];

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  final _pageController = PageController();
  final _innerNavKey = GlobalKey<NavigatorState>();

  int _stepIndex = 0;
  bool _loading = true;

  /// [ValueNotifier], not a plain field: [OnboardingAccountsStep] is built
  /// inside a route owned by the nested [Navigator] (`_innerNavKey`), whose
  /// `onGenerateInitialRoutes` only runs once — a `setState` on this State
  /// does not reliably propagate a rebuild into an already-pushed route's
  /// content. A `ValueListenableBuilder` subscribes directly, independent
  /// of that ancestor-rebuild path, so the list still updates live.
  final _accounts = ValueNotifier<List<Account>>(const []);

  /// Recurring items saved so far this wizard run — feeds the "Added" list
  /// on the recurring step so the user can see what's already covered
  /// instead of having to remember. Same [ValueNotifier] rebuild reason as
  /// [_accounts]: this step also lives inside the nested Navigator's
  /// already-built route.
  final _recurringItems = ValueNotifier<List<Transaction>>(const []);

  List<Account> get _currentAccounts => _accounts.value;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    unawaited(OnboardingAnalytics.recordStarted());
    List<Account> accounts = const [];
    try {
      accounts = await SupabaseService.fetchAccounts();
    } catch (_) {
      // Best-effort — an empty list still lets AddTransactionPage prompt
      // for an account via onAddAccount when the recurring step needs one
      // (Open Question #8: no step blocks reaching the dashboard).
    }
    if (!mounted) return;
    _accounts.value = accounts;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accounts.dispose();
    _recurringItems.dispose();
    super.dispose();
  }

  Future<void> _saveAccount(Account account) async {
    final saved = await SupabaseService.insertAccount(account);
    if (!mounted) return;
    _accounts.value = [..._accounts.value, saved];
  }

  void _openAddAccountDialog({AccountType initialType = AccountType.bank}) {
    showAddAccountDialog(context, initialType: initialType, onSave: _saveAccount);
  }

  Future<void> _saveTransactionDraft(TransactionDraft draft) async {
    // The accounts step runs before income/recurring specifically so this
    // is rare — only reachable if the user skipped every account-creation
    // opportunity. Skips silently rather than blocking (Open Question #8).
    final accounts = _currentAccounts;
    if (accounts.isEmpty) return;
    final account = accounts.firstWhere(
      (a) => a.id == draft.accountId,
      orElse: () => accounts.first,
    );
    final tx = draft.toTransaction(account: account);
    final saved = await SupabaseService.insertTransaction(tx);
    if (saved.isRecurring) {
      _recurringItems.value = [..._recurringItems.value, saved];
    }
  }

  void _advanceTo(int index) {
    if (index >= _stepCount) {
      unawaited(_complete());
      return;
    }
    setState(() => _stepIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppDurations.page,
      curve: AppCurves.emphasized,
    );
  }

  void _skipStep(int index) {
    unawaited(OnboardingAnalytics.recordStepSkipped(_stepIds[index]));
    _advanceTo(index + 1);
  }

  /// Moves back one step. Hardware back is blocked for the whole wizard
  /// (Open Question #4a); this in-UI button is the only way to go
  /// backward, per the resolved "Only in-UI Skip/Back buttons move between
  /// steps" decision. Doesn't undo anything already saved on the step
  /// being left — re-visiting a step and changing the value just
  /// overwrites it going forward again, same as editing any other setting.
  void _goBack(int currentIndex) {
    if (currentIndex <= 0) return;
    setState(() => _stepIndex = currentIndex - 1);
    _pageController.animateToPage(
      currentIndex - 1,
      duration: AppDurations.page,
      curve: AppCurves.emphasized,
    );
  }

  /// Idempotent-resume guard (Open Design Question D2): skip re-saving if
  /// a prior, interrupted attempt at this same wizard run already created
  /// the income transaction. Saves inline — no extra screen, matching the
  /// budget step (a single number doesn't need the full transaction form).
  Future<void> _saveIncome(double? amount, int? accountId) async {
    if (await OnboardingWizardStatus.instance.isIncomeStepDone()) {
      _advanceTo(5);
      return;
    }
    if (amount == null || amount <= 0) {
      unawaited(OnboardingAnalytics.recordStepSkipped('income'));
      _advanceTo(5);
      return;
    }

    final draft = TransactionDraft(
      kind: TransactionKind.income,
      categoryName: IncomeFlowHelpers.defaultCategory,
      amount: amount,
      accountId: accountId ?? (_currentAccounts.isEmpty ? null : _currentAccounts.first.id),
      recurring: IncomeFlowHelpers.applyCategoryRecurringDefaults(
        categoryName: IncomeFlowHelpers.defaultCategory,
        current: RecurringConfig(),
      ),
    );
    await _saveTransactionDraft(draft);
    await OnboardingWizardStatus.instance.markIncomeStepDone();
    if (!mounted) return;
    _advanceTo(5);
  }

  /// Each of the 3 kind rows on the recurring step calls this directly
  /// (no picker sheet in between — the rows are listed inline on the step
  /// itself). Explicitly user-triggered per tap, so — unlike income —
  /// there's no auto-resume duplicate risk to guard against: the user can
  /// come back to this same step and add another item any number of times,
  /// that's the intended flow, not a bug to prevent.
  Future<void> _addRecurring(RecurringKind kind) async {
    final draft = TransactionDraft(
      accountId: _currentAccounts.isEmpty ? null : _currentAccounts.first.id,
    );
    applyDraftFor(draft, kind);

    await _innerNavKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          accounts: _currentAccounts,
          initialDraft: draft,
          onAddAccount: _openAddAccountDialog,
          onSave: _saveTransactionDraft,
        ),
      ),
    );
  }

  Future<void> _complete() async {
    unawaited(OnboardingAnalytics.recordCompleted());
    await OnboardingWizardStatus.instance.markComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const LoadingState(label: 'Setting things up…'),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            OnboardingProgressHeader(
              stepIndex: _stepIndex,
              stepCount: _stepCount,
            ),
            Expanded(
              child: Navigator(
                key: _innerNavKey,
                onGenerateInitialRoutes: (navigator, initialRoute) => [
                  MaterialPageRoute(builder: (context) => _inlineSteps()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineSteps() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OnboardingNameStep(
          onSkip: () => _skipStep(0),
          onNext: () => _advanceTo(1),
        ),
        OnboardingCurrencyStep(
          onSkip: () => _skipStep(1),
          onNext: () => _advanceTo(2),
          onBack: () => _goBack(1),
        ),
        OnboardingBudgetStep(
          onSkip: () => _skipStep(2),
          onNext: () => _advanceTo(3),
          onBack: () => _goBack(2),
        ),
        ValueListenableBuilder<List<Account>>(
          valueListenable: _accounts,
          builder: (context, accounts, _) => OnboardingAccountsStep(
            accounts: accounts,
            onAddAccount: _openAddAccountDialog,
            onSkip: () => _skipStep(3),
            onNext: () => _advanceTo(4),
            onBack: () => _goBack(3),
          ),
        ),
        ValueListenableBuilder<List<Account>>(
          valueListenable: _accounts,
          builder: (context, accounts, _) => OnboardingIncomeStep(
            accounts: accounts,
            onSkip: () => _skipStep(4),
            onNext: (amount, accountId) =>
                unawaited(_saveIncome(amount, accountId)),
            onBack: () => _goBack(4),
          ),
        ),
        ValueListenableBuilder<List<Transaction>>(
          valueListenable: _recurringItems,
          builder: (context, items, _) => OnboardingRecurringIntroStep(
            items: items,
            onSkip: () => unawaited(_complete()),
            onPickKind: (kind) => unawaited(_addRecurring(kind)),
            onBack: () => _goBack(5),
          ),
        ),
      ],
    );
  }
}
