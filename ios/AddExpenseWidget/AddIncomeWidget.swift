import SwiftUI
import WidgetKit

private let addIncomeURL = URL(string: "expensetracker://add-income")!

struct AddIncomeEntry: TimelineEntry {
    let date: Date
}

struct AddIncomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> AddIncomeEntry {
        AddIncomeEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (AddIncomeEntry) -> Void) {
        completion(AddIncomeEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AddIncomeEntry>) -> Void) {
        let entry = AddIncomeEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct AddIncomeWidgetEntryView: View {
    var entry: AddIncomeProvider.Entry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(WidgetTheme.surface)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(WidgetTheme.success.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(WidgetTheme.success)
                }

                VStack(spacing: 2) {
                    Text("Add Income")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(WidgetTheme.textPrimary)
                    Text("Log money in")
                        .font(.caption2)
                        .foregroundColor(WidgetTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding()
        }
        .widgetURL(addIncomeURL)
    }
}

struct AddIncomeWidget: Widget {
    let kind: String = "AddIncomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AddIncomeProvider()) { entry in
            AddIncomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Add Income")
        .description("Quickly open the app to log income.")
        .supportedFamilies([.systemSmall])
    }
}
