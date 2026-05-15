import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/expense.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.init();
    runApp(const ExpenseTrackerApp());
  } catch (error) {
    runApp(ErrorApp(message: error.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      home: Scaffold(
        appBar: AppBar(title: const Text('Startup Error')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Unable to initialize Supabase.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text(
                'Run with --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;
  User? _user;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.currentUser;
    _authSubscription = SupabaseService.authStateChanges.listen((_) {
      setState(() {
        _user = SupabaseService.currentUser;
      });
    });
    _finishInitialization();
  }

  Future<void> _finishInitialization() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {
      _isInitializing = false;
      _user = SupabaseService.currentUser;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return LoginPage(onSignedIn: () {
        setState(() {
          _user = SupabaseService.currentUser;
        });
      });
    }

    return ExpenseHomePage(onSignOut: _signOut);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSignedIn,
  });

  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegistering) {
        await SupabaseService.signUpWithEmail(email, password);
      } else {
        await SupabaseService.signInWithEmail(email, password);
      }
      widget.onSignedIn();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(Object error) {
    final message = error is AuthException ? error.message : error.toString();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in / Register')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isRegistering ? 'Create an account' : 'Sign in to continue',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegistering ? 'Register' : 'Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isRegistering = !_isRegistering;
                              });
                            },
                      child: Text(_isRegistering
                          ? 'Already have an account? Sign in'
                          : 'Create a new account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({
    super.key,
    required this.onSignOut,
  });

  final VoidCallback onSignOut;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Expense> _expenses = [];
  bool _isLoading = true;

  static final List<String> _categories = [
    'Food',
    'Shopping',
    'Travel',
    'Bills',
    'Health',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await SupabaseService.fetchExpenses();
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(expenses);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load expenses: $error')),
      );
    }
  }

  Future<void> _saveExpense(Expense expense) async {
    try {
      final savedExpense = await SupabaseService.insertExpense(expense);
      if (!mounted) return;
      setState(() {
        _expenses.insert(0, savedExpense);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save expense: $error')),
      );
    }
  }

  void _openAddExpenseDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AddExpenseDialog(
        categories: _categories,
        onSave: _saveExpense,
      ),
    );
  }

  double get _totalAmount => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  int get _recurringCount => _expenses.where((expense) => expense.isRecurring).length;

  String get _currentEmail => SupabaseService.currentUser?.email ?? 'Unknown user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
            tooltip: 'Sign out',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseDialog,
            tooltip: 'Add expense',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as $_currentEmail', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            Expanded(child: _buildExpenseList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total expenses', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$').format(_totalAmount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_expenses.length} entries', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text('$_recurringCount recurring', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expenses.isEmpty) {
      return Center(
        child: Text(
          'No expenses yet. Tap + to add one.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(expense.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(expense.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(expense.category, Icons.label_outline),
                    _buildChip(expense.accountType.label, Icons.account_balance_wallet),
                    _buildChip(expense.type.label, Icons.repeat),
                    _buildChip(DateFormat.yMMMd().format(expense.date), Icons.calendar_month),
                    if (expense.endDate != null)
                      _buildChip('Ends ${DateFormat.yMMMd().format(expense.endDate!)}', Icons.stop_circle),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({
    super.key,
    required this.categories,
    required this.onSave,
  });

  final List<String> categories;
  final void Function(Expense expense) onSave;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategory;
  AccountType _selectedAccount = AccountType.bank;
  ExpenseType _selectedType = ExpenseType.oneTime;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isEndDate) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_selectedEndDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate == null) return;
    setState(() {
      if (isEndDate) {
        _selectedEndDate = newDate;
      } else {
        _selectedDate = newDate;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text) ?? 0;

    widget.onSave(
      Expense(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        accountType: _selectedAccount,
        endDate: _selectedType == ExpenseType.recurring ? _selectedEndDate : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: widget.categories
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                value: _selectedAccount,
                items: AccountType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAccount = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Account type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseType>(
                value: _selectedType,
                items: ExpenseType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Expense type'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                    ),
                  ),
                ],
              ),
              if (_selectedType == ExpenseType.recurring) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(context, true),
                        child: Text(_selectedEndDate == null
                            ? 'Select end date'
                            : 'Ends: ${DateFormat.yMMMd().format(_selectedEndDate!)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
