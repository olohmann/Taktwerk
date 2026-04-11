import SwiftUI

struct ScheduleView: View {
    let config: PlistConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.headline)

            if let interval = config.startInterval {
                HStack {
                    Label("Interval", systemImage: "timer")
                        .font(.subheadline)
                    Text("Every \(interval.formattedInterval)")
                        .foregroundStyle(.secondary)
                }
            }

            if let intervals = config.startCalendarInterval {
                Label("Calendar Schedule", systemImage: "calendar")
                    .font(.subheadline)

                ForEach(Array(intervals.enumerated()), id: \.offset) { _, interval in
                    HStack {
                        Text(interval.summary)
                            .font(.body)
                        Spacer()
                        if let nextFire = interval.nextFireDate() {
                            Text("Next: \(nextFire, style: .relative)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
}
