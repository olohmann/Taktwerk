import SwiftUI

struct ScheduleEditorView: View {
    @Bindable var viewModel: JobEditorViewModel

    var body: some View {
        switch viewModel.scheduleType {
        case .none:
            Text("No schedule configured. The agent will only run at load (if enabled).")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .interval:
            LabeledContent("Run every (seconds)") {
                TextField("300", text: $viewModel.startInterval)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
            }
            if let seconds = UInt64(viewModel.startInterval) {
                Text("Runs every \(seconds.formattedInterval)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .calendar:
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Minute").font(.caption).foregroundStyle(.secondary)
                    TextField("*", text: $viewModel.calendarMinute)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("0–59").font(.caption2).foregroundStyle(.tertiary)
                }

                GridRow {
                    Text("Hour").font(.caption).foregroundStyle(.secondary)
                    TextField("*", text: $viewModel.calendarHour)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("0–23").font(.caption2).foregroundStyle(.tertiary)
                }

                GridRow {
                    Text("Day").font(.caption).foregroundStyle(.secondary)
                    TextField("*", text: $viewModel.calendarDay)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("1–31").font(.caption2).foregroundStyle(.tertiary)
                }

                GridRow {
                    Text("Weekday").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $viewModel.calendarWeekday) {
                        Text("Any").tag(nil as Int?)
                        Text("Sunday").tag(0 as Int?)
                        Text("Monday").tag(1 as Int?)
                        Text("Tuesday").tag(2 as Int?)
                        Text("Wednesday").tag(3 as Int?)
                        Text("Thursday").tag(4 as Int?)
                        Text("Friday").tag(5 as Int?)
                        Text("Saturday").tag(6 as Int?)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 140, alignment: .leading)
                    Text("0=Sun … 6=Sat").font(.caption2).foregroundStyle(.tertiary)
                }

                GridRow {
                    Text("Month").font(.caption).foregroundStyle(.secondary)
                    TextField("*", text: $viewModel.calendarMonth)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("1–12").font(.caption2).foregroundStyle(.tertiary)
                }
            }

            // Next run preview
            let interval = CalendarInterval(
                minute: UInt32(viewModel.calendarMinute),
                hour: UInt32(viewModel.calendarHour),
                day: UInt32(viewModel.calendarDay),
                weekday: viewModel.calendarWeekday.map { UInt32($0) },
                month: UInt32(viewModel.calendarMonth)
            )
            if let nextFire = interval.nextFireDate() {
                Text("Next run: \(nextFire, format: .dateTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
