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
                .fill(Color(red: 0.0, green: 0.16, blue: 0.13))

            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 0.78, blue: 0.59))

                Text("Add expense")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
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
