import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/dialogs/add_account_dialog.dart';
import '../../components/transaction/account_chips_selector.dart';
import '../../components/transaction/amount_numeric_keypad.dart';
import '../../components/transaction/amount_section.dart';
import '../../components/transaction/category_pills_selector.dart';
import '../../components/transaction/income_category_pills_selector.dart';
import '../../components/transaction/quick_ai_input.dart';
import '../../components/transaction/recent_suggestions_section.dart';
import '../../components/transaction/recurring_payment_section.dart';
import '../../components/transaction/source_payer_field.dart';
import '../../components/transaction/sticky_bottom_cta.dart';
import '../../components/transaction/transaction_app_bar.dart';
import '../../components/transaction/transaction_details_card.dart';
import '../../components/transaction/transaction_type_selector.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/income_category_catalog.dart';
import '../../components/transaction/transaction_subtype_chips.dart';
import '../../utils/income_flow_helpers.dart';
import '../../utils/transaction_subtype_helpers.dart';
import '../../utils/snackbar_helper.dart';

/// The most important screen in the app: expense entry under 3 seconds.
///
/// Architectural notes:
///
/// * The screen owns a single mutable [TransactionDraft] plus a handful of
///   UI-only flags (expanded panels, busy state, focus nodes). Every section
///   widget is stateless w.r.t. business data — they receive the slice they
///   need and emit changes back through callbacks. This keeps the form
///   trivial to migrate to Riverpod / Bloc later: replace [setState] with
///   the equivalent notifier and the section widgets stay untouched.
///
/// * Persistence is intentionally decoupled. The screen takes [onSave] —
///   the caller maps the draft into whatever storage model is appropriate
///   (today: [Expense]). Income / EMI / subscription land here
///   too once the persistence model grows.
///
/// * Layout is `Scaffold` with a sticky bottom action bar. The body
///   scrolls; the bar floats. `resizeToAvoidBottomInset` lets the keyboard
///   push the CTA up so it stays thumb-reachable.
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    required this.accounts,
    required this.onSave,
    this.recentSuggestions = const [],
    this.recentCategoryNames = const [],
    this.recentIncomeSuggestions = const [],
    this.recentIncomeCategoryNames = const [],
    this.recentPayers = const [],
    this.initialDraft,
    this.onAddAccount,
  });

  final List<Account> accounts;

  /// Called when the user taps Save. Returns once persistence is done so the
  /// screen can show a busy state.
  final Future<void> Function(TransactionDraft draft) onSave;

  /// Optional autofill suggestions (recent merchants / payers).
  final List<RecentSuggestion> recentSuggestions;

  /// Category names to bubble to the front of the pill list.
  final List<String> recentCategoryNames;

  /// Income-mode autofill rows (category · payer format).
  final List<RecentSuggestion> recentIncomeSuggestions;

  /// Recently used income category names.
  final List<String> recentIncomeCategoryNames;

  /// Reusable payer / employer history for income source field.
  final List<String> recentPayers;

  final TransactionDraft? initialDraft;

  /// Surfaced when the account list is empty so the user can jump to
  /// add-account flow without leaving the screen.
  final OnAddAccount? onAddAccount;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TransactionDraft _draft;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _merchantFocus = FocusNode();
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  bool _detailsExpanded = true;
  bool _isBusy = false;
  bool _amountKeypadOpen = true;

  @override
  void initState() {
    super.initState();
    _hydrateDraft();
    _amountController.addListener(_syncAmountToDraft);
    _merchantController.addListener(_syncMerchantToDraft);
    _noteController.addListener(_syncNoteToDraft);
    _merchantFocus.addListener(_onMerchantFocusChanged);
  }

  void _onMerchantFocusChanged() {
    if (_merchantFocus.hasFocus) {
      _setAmountKeypadOpen(false);
    }
  }

  void _hydrateDraft() {
    final currency = CurrencySettings.instance;
    _draft =
        widget.initialDraft ??
        TransactionDraft(
          currencyCode: currency.currencyCode,
          accountId: widget.accounts.isEmpty ? null : widget.accounts.first.id,
          categoryName: _defaultCategory(),
        );
    if (_draft.amount != null) {
      _amountController.text = _draft.amount!.toStringAsFixed(
        currency.decimalDigits,
      );
    }
    _merchantController.text = _draft.merchant;
    _noteController.text = _draft.note;
  }

  String? _defaultCategory() {
    final catalog = CategoryCatalog.instance;
    if (catalog.names.isNotEmpty) return catalog.names.first;
    return null;
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_syncAmountToDraft)
      ..dispose();
    _merchantFocus.removeListener(_onMerchantFocusChanged);
    _merchantController
      ..removeListener(_syncMerchantToDraft)
      ..dispose();
    _merchantFocus.dispose();
    _noteController
      ..removeListener(_syncNoteToDraft)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncAmountToDraft() {
    final raw = _amountController.text;
    _draft.amount = double.tryParse(raw);
  }

  void _syncMerchantToDraft() {
    _draft.merchant = _merchantController.text;
  }

  void _syncNoteToDraft() {
    _draft.note = _noteController.text;
  }

  Account? get _selectedAccount {
    if (widget.accounts.isEmpty) return null;
    return widget.accounts.firstWhere(
      (a) => a.id == _draft.accountId,
      orElse: () => widget.accounts.first,
    );
  }

  void _onKindChanged(TransactionKind kind) {
    setState(() {
      _draft.kind = kind;
      if (kind == TransactionKind.income) {
        _draft.categoryName ??= IncomeFlowHelpers.defaultCategory;
        _detailsExpanded = false;
        _draft.recurring = IncomeFlowHelpers.applyCategoryRecurringDefaults(
          categoryName: _draft.categoryName,
          current: _draft.recurring,
        );
      } else if (kind == TransactionKind.transfer) {
        _draft.categoryName ??= 'Transfer';
        _detailsExpanded = true;
        _draft.recurring = RecurringConfig();
        if (_draft.transferToAccountId == null && widget.accounts.length > 1) {
          _draft.transferToAccountId = widget.accounts[1].id;
        }
      } else {
        _draft.categoryName ??= _defaultCategory();
        _detailsExpanded = true;
      }
    });
  }

  void _onTransferToChanged(Account account) {
    setState(() => _draft.transferToAccountId = account.id);
  }

  void _onCategoryChanged(String name) {
    setState(() {
      _draft.categoryName = name;
      if (_draft.isIncome) {
        _draft.recurring = IncomeFlowHelpers.applyCategoryRecurringDefaults(
          categoryName: name,
          current: _draft.recurring,
        );
        _applySalaryAutofillIfNeeded(name);
      }
    });
  }

  /// Pre-fills employer / amount / account from the latest salary suggestion.
  void _applySalaryAutofillIfNeeded(String categoryName) {
    if (categoryName != 'Salary') return;
    RecentSuggestion? match;
    for (final s in widget.recentIncomeSuggestions) {
      if (s.category == 'Salary') {
        match = s;
        break;
      }
    }
    if (match == null) return;
    if (_merchantController.text.trim().isEmpty && match.merchant.isNotEmpty) {
      _merchantController.text = match.merchant;
      _draft.merchant = match.merchant;
    }
    if ((_draft.amount ?? 0) <= 0 && match.amount != null) {
      _amountController.text = match.amount!.toStringAsFixed(
        CurrencySettings.instance.decimalDigits,
      );
      _draft.amount = match.amount;
    }
    if (match.accountId != null) {
      _draft.accountId = match.accountId;
    }
    if (match.recurring != null && !_draft.recurring.enabled) {
      _draft.recurring = match.recurring!.copyWith(enabled: true);
    }
  }

  void _onAccountChanged(Account account) {
    setState(() => _draft.accountId = account.id);
  }

  void _onRecurringChanged(RecurringConfig config) {
    setState(() => _draft.recurring = config);
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickTransactionDate() {
    return _pickDate(
      initial: _draft.date,
      onPicked: (value) => setState(() => _draft.date = value),
    );
  }

  Future<void> _pickStartDate() {
    return _pickDate(
      initial: _draft.recurring.startDate,
      onPicked: (value) {
        setState(() {
          _draft.recurring = _draft.recurring.copyWith(startDate: value);
        });
      },
    );
  }

  Future<void> _pickEndDate() {
    return _pickDate(
      initial: _draft.recurring.endDate ?? _draft.recurring.startDate,
      firstDate: _draft.recurring.startDate,
      onPicked: (value) {
        setState(() {
          _draft.recurring = _draft.recurring.copyWith(endDate: value);
        });
      },
    );
  }

  void _applyQuickDate(DateQuickOption option) {
    final now = DateTime.now();
    switch (option) {
      case DateQuickOption.today:
        setState(() => _draft.date = DateTime(now.year, now.month, now.day));
        break;
      case DateQuickOption.yesterday:
        final y = now.subtract(const Duration(days: 1));
        setState(() => _draft.date = DateTime(y.year, y.month, y.day));
        break;
      case DateQuickOption.pick:
        _pickTransactionDate();
        break;
    }
  }

  void _applySuggestion(RecentSuggestion suggestion) {
    setState(() {
      _merchantController.text = suggestion.merchant;
      _draft.merchant = suggestion.merchant;
      _draft.categoryName = suggestion.category;
      if (suggestion.accountId != null) {
        _draft.accountId = suggestion.accountId;
      }
      if (suggestion.amount != null) {
        _amountController.text = suggestion.amount!.toStringAsFixed(
          CurrencySettings.instance.decimalDigits,
        );
        _draft.amount = suggestion.amount;
      }
      if (suggestion.recurring != null) {
        _draft.recurring = suggestion.recurring!;
      }
    });
    final label = _draft.isIncome
        ? IncomeFlowHelpers.suggestionDisplayLabel(
            category: suggestion.category,
            payer: suggestion.merchant,
          )
        : suggestion.merchant;
    SnackbarHelper.showMessage(context, 'Filled from $label');
  }

  void _applyPayerChip(String payer) {
    setState(() {
      _merchantController.text = payer;
      _draft.merchant = payer;
    });
  }

  void _handleQuickParse(String raw) {
    final result = _QuickParser.parse(
      raw,
      accounts: widget.accounts,
      catalog: CategoryCatalog.instance,
    );

    setState(() {
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(
          CurrencySettings.instance.decimalDigits,
        );
        _draft.amount = result.amount;
      }
      if (result.merchant != null) {
        _merchantController.text = result.merchant!;
        _draft.merchant = result.merchant!;
      }
      if (result.accountId != null) _draft.accountId = result.accountId;
      if (result.categoryName != null) {
        _draft.categoryName = result.categoryName;
      }
    });

    SnackbarHelper.showSuccess(context, 'Parsed: $raw');
  }

  void _setAmountKeypadOpen(bool open) {
    if (_amountKeypadOpen == open) return;
    setState(() => _amountKeypadOpen = open);
  }

  void _openCurrencyPicker() {
    _setAmountKeypadOpen(false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            itemCount: CurrencySettings.supported.length,
            itemBuilder: (context, index) {
              final option = CurrencySettings.supported[index];
              final selected =
                  option.code == CurrencySettings.instance.currencyCode;
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: selected
                      ? AppColors.primary.withAlpha(36)
                      : AppColors.surfaceSecondary,
                  child: Text(
                    option.symbol,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  option.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(option.code, style: AppTextStyles.caption),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () async {
                  await CurrencySettings.instance.setCurrency(option.code);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (!mounted) return;
                  setState(() {
                    _draft.currencyCode = option.code;
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  bool _validate() {
    if ((_draft.amount ?? 0) <= 0) {
      SnackbarHelper.showWarning(context, 'Enter an amount greater than zero');
      _setAmountKeypadOpen(true);
      return false;
    }
    if (_selectedAccount == null) {
      SnackbarHelper.showWarning(context, 'Select an account');
      return false;
    }
    if (_draft.isTransfer) {
      if (_draft.transferToAccountId == null) {
        SnackbarHelper.showWarning(context, 'Select a destination account');
        return false;
      }
      if (_draft.transferToAccountId == _draft.accountId) {
        SnackbarHelper.showWarning(
          context,
          'From and to accounts must be different',
        );
        return false;
      }
      return true;
    }
    if (_draft.categoryName == null) {
      SnackbarHelper.showWarning(context, 'Pick a category');
      return false;
    }
    return true;
  }

  Future<void> _onSave({required bool addAnother}) async {
    if (!_validate()) return;
    setState(() => _isBusy = true);
    try {
      await widget.onSave(_draft);
      if (!mounted) return;
      if (addAnother) {
        _resetForAnother();
      } else {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _resetForAnother() {
    setState(() {
      _amountController.clear();
      _merchantController.clear();
      _noteController.clear();
      _draft = TransactionDraft(
        kind: _draft.kind,
        accountId: _draft.accountId,
        categoryName: _draft.categoryName,
        currencyCode: _draft.currencyCode,
      );
      _detailsExpanded = true;
      _amountKeypadOpen = true;
    });
    _scrollController.animateTo(
      0,
      duration: AppDurations.page,
      curve: AppCurves.spring,
    );
  }

  Color _accentColor() {
    if (_draft.categoryName == null) return AppColors.primary;
    if (_draft.isIncome) {
      return IncomeCategoryCatalog.instance.colorForName(_draft.categoryName!);
    }
    return CategoryCatalog.instance.colorForName(_draft.categoryName!);
  }

  List<String> _payerSuggestionsForCategory() {
    return IncomeFlowHelpers.filterPayerSuggestions(
      categoryName: _draft.categoryName,
      allPayers: widget.recentPayers,
    );
  }

  List<Widget> _buildIncomeSections() {
    final incomeSuggestions = widget.recentIncomeSuggestions;
    return [
      AmountSection(
        controller: _amountController,
        keypadOpen: _amountKeypadOpen,
        onKeypadOpenChanged: _setAmountKeypadOpen,
        accent: _accentColor(),
        onChangeCurrency: _openCurrencyPicker,
        helperText: 'Where did this money come from?',
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionTypeSelector(
          selected: _draft.kind,
          onChanged: _onKindChanged,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'Income category'),
      const SizedBox(height: AppSpacing.sm),
      IncomeRefundChip(
        selectedCategory: _draft.categoryName,
        onSelected: () {
          setState(() {
            TransactionSubtypeHelpers.applyIncomeRefund(_draft);
            _applySalaryAutofillIfNeeded(
              TransactionSubtypeHelpers.incomeCategoryRefund,
            );
          });
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      IncomeCategoryPillsSelector(
        selectedName: _draft.categoryName,
        prioritisedNames: widget.recentIncomeCategoryNames,
        onChanged: _onCategoryChanged,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'Deposit to'),
      const SizedBox(height: AppSpacing.sm),
      AccountChipsSelector(
        accounts: widget.accounts,
        selectedAccountId: _draft.accountId,
        onChanged: _onAccountChanged,
        onAddAccount: widget.onAddAccount,
      ),
      const SizedBox(height: AppSpacing.lg),
      SourcePayerField(
        label: IncomeFlowHelpers.payerFieldLabel(_draft.categoryName),
        hintText: IncomeFlowHelpers.payerFieldHint(_draft.categoryName),
        controller: _merchantController,
        focusNode: _merchantFocus,
        recentPayers: _payerSuggestionsForCategory(),
        onPayerSelected: _applyPayerChip,
      ),
      if (incomeSuggestions.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        RecentSuggestionsSection(
          suggestions: incomeSuggestions,
          title: 'Recent income',
          showCategoryPrefix: true,
          onTap: _applySuggestion,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionDetailsCard(
          layout: TransactionDetailsLayout.incomeSecondaryOnly,
          expanded: _detailsExpanded,
          onExpandToggle: () =>
              setState(() => _detailsExpanded = !_detailsExpanded),
          date: _draft.date,
          onPickDate: _pickTransactionDate,
          onQuickDate: _applyQuickDate,
          noteController: _noteController,
          noteHintText: IncomeFlowHelpers.noteFieldHint(_draft.categoryName),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: RecurringPaymentSection(
          config: _draft.recurring,
          onChanged: _onRecurringChanged,
          onPickStartDate: _pickStartDate,
          onPickEndDate: _pickEndDate,
          isIncome: true,
          reminderHint: IncomeFlowHelpers.recurringReminderHint(
            _draft.categoryName,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildExpenseSections() {
    return [
      AmountSection(
        controller: _amountController,
        keypadOpen: _amountKeypadOpen,
        onKeypadOpenChanged: _setAmountKeypadOpen,
        accent: _accentColor(),
        onChangeCurrency: _openCurrencyPicker,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionTypeSelector(
          selected: _draft.kind,
          onChanged: _onKindChanged,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'Quick type'),
      const SizedBox(height: AppSpacing.sm),
      ExpenseSubtypeChips(
        selectedCategory: _draft.categoryName,
        onSubtypeSelected: (label) {
          setState(() {
            TransactionSubtypeHelpers.applyExpenseSubtype(_draft, label);
          });
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'Category'),
      const SizedBox(height: AppSpacing.sm),
      CategoryPillsSelector(
        selectedName: _draft.categoryName,
        prioritisedNames: widget.recentCategoryNames,
        onChanged: _onCategoryChanged,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'Account'),
      const SizedBox(height: AppSpacing.sm),
      AccountChipsSelector(
        accounts: widget.accounts,
        selectedAccountId: _draft.accountId,
        onChanged: _onAccountChanged,
        onAddAccount: widget.onAddAccount,
      ),
      if (widget.recentSuggestions.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        RecentSuggestionsSection(
          suggestions: widget.recentSuggestions,
          onTap: _applySuggestion,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionDetailsCard(
          expanded: _detailsExpanded,
          onExpandToggle: () =>
              setState(() => _detailsExpanded = !_detailsExpanded),
          merchantController: _merchantController,
          merchantFocus: _merchantFocus,
          date: _draft.date,
          onPickDate: _pickTransactionDate,
          onQuickDate: _applyQuickDate,
          noteController: _noteController,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: RecurringPaymentSection(
          config: _draft.recurring,
          onChanged: _onRecurringChanged,
          onPickStartDate: _pickStartDate,
          onPickEndDate: _pickEndDate,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: QuickAiInput(onParse: _handleQuickParse),
      ),
    ];
  }

  List<Widget> _buildTransferSections() {
    return [
      AmountSection(
        controller: _amountController,
        keypadOpen: _amountKeypadOpen,
        onKeypadOpenChanged: _setAmountKeypadOpen,
        accent: AppColors.secondary,
        onChangeCurrency: _openCurrencyPicker,
        helperText: 'Move money between accounts',
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionTypeSelector(
          selected: _draft.kind,
          onChanged: _onKindChanged,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'From account'),
      const SizedBox(height: AppSpacing.sm),
      AccountChipsSelector(
        accounts: widget.accounts,
        selectedAccountId: _draft.accountId,
        onChanged: _onAccountChanged,
        onAddAccount: widget.onAddAccount,
        heading: 'From account',
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionHeading(title: 'To account'),
      const SizedBox(height: AppSpacing.sm),
      AccountChipsSelector(
        accounts: widget.accounts,
        selectedAccountId: _draft.transferToAccountId,
        onChanged: _onTransferToChanged,
        onAddAccount: widget.onAddAccount,
        heading: 'To account',
      ),
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TransactionDetailsCard(
          layout: TransactionDetailsLayout.incomeSecondaryOnly,
          expanded: _detailsExpanded,
          onExpandToggle: () =>
              setState(() => _detailsExpanded = !_detailsExpanded),
          date: _draft.date,
          onPickDate: _pickTransactionDate,
          onQuickDate: _applyQuickDate,
          noteController: _noteController,
          noteHintText: 'Optional note',
        ),
      ),
    ];
  }

  String get _appBarTitle {
    if (_draft.isEditing) return 'Edit Transaction';
    switch (_draft.kind) {
      case TransactionKind.income:
        return 'Add Income';
      case TransactionKind.transfer:
        return 'Add Transfer';
      case TransactionKind.expense:
        return 'Add Transaction';
    }
  }

  String get _saveLabel {
    if (_draft.isEditing) return 'Save Changes';
    switch (_draft.kind) {
      case TransactionKind.income:
        return 'Save Income';
      case TransactionKind.transfer:
        return 'Save Transfer';
      case TransactionKind.expense:
        return 'Save Transaction';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = switch (_draft.kind) {
      TransactionKind.income => _buildIncomeSections(),
      TransactionKind.transfer => _buildTransferSections(),
      TransactionKind.expense => _buildExpenseSections(),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          TransactionAppBar(title: _appBarTitle, onMic: null),
          Expanded(
            child:
                ListenableBuilder(
                      listenable: CategoryCatalog.instance,
                      builder: (context, _) {
                        return GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTap: () {
                            _setAmountKeypadOpen(false);
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: sections,
                            ),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(duration: AppDurations.page)
                    .slideY(
                      begin: 0.02,
                      end: 0,
                      duration: AppDurations.page,
                      curve: AppCurves.spring,
                    ),
          ),
          AnimatedSize(
            duration: AppDurations.short,
            curve: AppCurves.spring,
            alignment: Alignment.topCenter,
            child: _amountKeypadOpen
                ? AmountNumericKeypad(
                    controller: _amountController,
                    maxDecimalDigits: CurrencySettings.instance.decimalDigits,
                    accent: _accentColor(),
                    onDone: () => _setAmountKeypadOpen(false),
                  )
                : const SizedBox(width: double.infinity),
          ),
          StickyBottomCTA(
            isBusy: _isBusy,
            saveLabel: _saveLabel,
            showSaveAndAddAnother: !_draft.isEditing,
            onSave: () => _onSave(addAnother: false),
            onSaveAndAddAnother: () => _onSave(addAnother: true),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny in-file parser for the AI quick-entry input. Lives here (not in
/// services) because it's UX shorthand, not a service. Easy to lift into a
/// dedicated parser once the real implementation grows. Pattern is roughly:
///
///   `[amount] [merchant words] (using|via|with|on) [account]`
class _QuickParser {
  static _QuickParseResult parse(
    String raw, {
    required List<Account> accounts,
    required CategoryCatalog catalog,
  }) {
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    final amount = amountMatch == null
        ? null
        : double.tryParse(amountMatch.group(1)!);

    final accountTokens = const ['using', 'via', 'with', 'on'];
    int? accountId;
    String working = raw;
    for (final token in accountTokens) {
      final idx = working.toLowerCase().indexOf(' $token ');
      if (idx == -1) continue;
      final tail = working.substring(idx + token.length + 2).trim();
      final match = accounts.firstWhere(
        (a) => tail.toLowerCase().contains(a.name.toLowerCase()),
        orElse: () => Account(name: '__none__', type: AccountType.bank),
      );
      if (match.name != '__none__' && match.id != null) {
        accountId = match.id;
      }
      working = working.substring(0, idx);
      break;
    }

    final merchantRaw = working
        .replaceFirst(amountMatch?.group(1) ?? '', '')
        .trim();
    final merchant = merchantRaw.isEmpty ? null : merchantRaw;

    String? categoryName;
    if (merchant != null) {
      for (final c in catalog.categories) {
        if (merchant.toLowerCase().contains(c.name.toLowerCase())) {
          categoryName = c.name;
          break;
        }
      }
    }

    return _QuickParseResult(
      amount: amount,
      merchant: merchant,
      accountId: accountId,
      categoryName: categoryName,
    );
  }
}

class _QuickParseResult {
  const _QuickParseResult({
    this.amount,
    this.merchant,
    this.accountId,
    this.categoryName,
  });

  final double? amount;
  final String? merchant;
  final int? accountId;
  final String? categoryName;
}
