import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Isolated test of the exact navigation mechanism ExpenseHomePage's
/// `_openBudgetsFromSettings` uses: Money is pushed 2 Navigator levels
/// deep from the tab shell (Settings tab body -> pushed Money page), so
/// switching to the Budgets tab requires popping back to the root route
/// before the tab-index state change is visible.
///
/// This does not pump the real ExpenseHomePage — that needs Supabase/Auth0
/// bootstrap this repo has no test mocking for yet (tracked separately in
/// TODOS.md). This harness reproduces the same structure (root Scaffold
/// with a tab-index-driven body, a pushed route two levels deep, a button
/// wired to `popUntil((r) => r.isFirst)` + `setState`) so the mechanism
/// itself — the thing flagged as genuinely new and untested — gets a real
/// assertion.
void main() {
  testWidgets(
    'popUntil + setState lands on the target tab from a route pushed 2 levels deep',
    (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: selectedIndex == 3
                    ? const Text('Budgets tab body')
                    : ElevatedButton(
                        onPressed: () {
                          // Settings tab body -> push "Money"
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => Scaffold(
                                body: ElevatedButton(
                                  onPressed: () {
                                    // Money -> push a second level, mirroring
                                    // Settings -> Money's real depth.
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) => Scaffold(
                                          body: ElevatedButton(
                                            child: const Text('Open Budgets'),
                                            onPressed: () {
                                              Navigator.of(
                                                context,
                                              ).popUntil((r) => r.isFirst);
                                              setState(
                                                () => selectedIndex = 3,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Go 1 level deeper'),
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('Open Settings'),
                      ),
              );
            },
          ),
        ),
      );

      expect(find.text('Open Settings'), findsOneWidget);

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go 1 level deeper'));
      await tester.pumpAndSettle();

      expect(find.text('Open Budgets'), findsOneWidget);

      await tester.tap(find.text('Open Budgets'));
      await tester.pumpAndSettle();

      // The two pushed routes are gone and the tab body shows Budgets —
      // this is the exact assertion the review flagged as missing.
      expect(find.text('Budgets tab body'), findsOneWidget);
      expect(find.text('Open Budgets'), findsNothing);
      expect(find.text('Go 1 level deeper'), findsNothing);
    },
  );
}
