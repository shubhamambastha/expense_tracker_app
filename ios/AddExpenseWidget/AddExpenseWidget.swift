import SwiftUI
import WidgetKit

private let addExpenseURL = URL(string: "expensetracker://add-expense")!

struct AddExpenseEntry: TimelineEntry {
    let date: Date
}

struct AddExpenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> AddExpenseEntry {
        AddExpenseEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (AddExpenseEntry) -> Void) {
        completion(AddExpenseEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AddExpenseEntry>) -> Void) {
        let entry = AddExpenseEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct AddExpenseWidgetEntryView: View {
    var entry: AddExpenseProvider.Entry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(WidgetTheme.surface)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(WidgetTheme.teal.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(WidgetTheme.teal)
                }

                VStack(spacing: 2) {
                    Text("Add Expense")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(WidgetTheme.textPrimary)
                    Text("Log a purchase")
                        .font(.caption2)
                        .foregroundColor(WidgetTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding()
        }
        .widgetURL(addExpenseURL)
    }
}

struct AddExpenseWidget: Widget {
    let kind: String = "AddExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AddExpenseProvider()) { entry in
            AddExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Add Expense")
        .description("Quickly open the app to log a new expense.")
        .supportedFamilies([.systemSmall])
    }
}
