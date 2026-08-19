import SwiftUI
import WidgetKit

private let analyticsURL = URL(string: "expensetracker://open-analytics")!

struct QuickActionsEntry: TimelineEntry {
    let date: Date
}

struct QuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionsEntry {
        QuickActionsEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        completion(QuickActionsEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        let entry = QuickActionsEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickActionsWidgetEntryView: View {
    var entry: QuickActionsProvider.Entry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(WidgetTheme.surface)

            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK ACTIONS")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(WidgetTheme.textTertiary)
                    .tracking(0.4)

                HStack(spacing: 0) {
                    WidgetActionButton(
                        icon: "minus.circle.fill",
                        label: "Expense",
                        tint: WidgetTheme.teal,
                        destination: URL(string: "expensetracker://add-expense")!
                    )
                    WidgetActionButton(
                        icon: "plus.circle.fill",
                        label: "Income",
                        tint: WidgetTheme.success,
                        destination: URL(string: "expensetracker://add-income")!
                    )
                    WidgetActionButton(
                        icon: "chart.pie.fill",
                        label: "Analytics",
                        tint: WidgetTheme.secondary,
                        destination: analyticsURL
                    )
                }
            }
            .padding()
        }
        .widgetURL(analyticsURL)
    }
}

struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsProvider()) { entry in
            QuickActionsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Add an expense or income, or jump to Analytics.")
        .supportedFamilies([.systemMedium])
    }
}
