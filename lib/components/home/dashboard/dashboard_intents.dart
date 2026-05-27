/// Single source of truth for the four home-screen quick actions.
///
/// Kept as a plain enum so the dashboard widgets stay independent from
/// `ExpenseHomePage` while still expressing the user's intent.
enum QuickAction { addExpense, addIncome, transfer, addEmi }
