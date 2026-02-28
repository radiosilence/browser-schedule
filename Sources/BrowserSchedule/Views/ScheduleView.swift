import BrowserScheduleCore
import SwiftUI

private let timeFormatter: DateFormatter = {
  let f = DateFormatter()
  f.dateFormat = "H:mm"
  return f
}()

private func dateFromTimeString(_ s: String) -> Date {
  timeFormatter.date(from: s) ?? timeFormatter.date(from: "0:00")!
}

private func timeStringFromDate(_ d: Date) -> String {
  timeFormatter.string(from: d)
}

struct ScheduleView: View {
  @Environment(ConfigManager.self) private var configManager
  @Binding var scope: EditingScope

  @State private var startDate = dateFromTimeString("9:00")
  @State private var endDate = dateFromTimeString("18:00")

  private let dayOptions = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  var body: some View {
    @Bindable var cm = configManager

    VStack(spacing: 0) {
      Form {
        // Work Hours
        Section {
          if scope == .main {
            DatePicker(
              "Start Time", selection: $startDate, displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.stepperField)
            DatePicker("End Time", selection: $endDate, displayedComponents: .hourAndMinute)
              .datePickerStyle(.stepperField)
          } else {
            OverridableDatePicker(
              label: "Start Time",
              inherited: configManager.workStartTime,
              override: $cm.localWorkStartTime
            )
            OverridableDatePicker(
              label: "End Time",
              inherited: configManager.workEndTime,
              override: $cm.localWorkEndTime
            )
          }

          if isNightShift {
            Label(
              "Night shift detected (hours span midnight)",
              systemImage: "moon.fill"
            )
            .foregroundStyle(.secondary)
            .font(.callout)
          }
        } header: {
          Label("Work Hours", systemImage: "clock")
        }

        // Work Days
        Section {
          if scope == .main {
            LabeledContent("Start Day") {
              Picker("", selection: $cm.workStartDay) {
                ForEach(dayOptions, id: \.self) { Text($0).tag($0) }
              }
              .labelsHidden()
              .frame(width: 120)
            }
            LabeledContent("End Day") {
              Picker("", selection: $cm.workEndDay) {
                ForEach(dayOptions, id: \.self) { Text($0).tag($0) }
              }
              .labelsHidden()
              .frame(width: 120)
            }
          } else {
            OverridableDayPicker(
              label: "Start Day",
              inherited: configManager.workStartDay,
              override: $cm.localWorkStartDay,
              options: dayOptions
            )
            OverridableDayPicker(
              label: "End Day",
              inherited: configManager.workEndDay,
              override: $cm.localWorkEndDay,
              options: dayOptions
            )
          }
        } header: {
          Label("Work Days", systemImage: "calendar")
        }

        // Status
        Section {
          LabeledContent("Current Period") {
            HStack(spacing: 8) {
              Image(
                systemName: isCurrentlyWorkTime
                  ? "briefcase.fill" : "house.fill"
              )
              .foregroundStyle(isCurrentlyWorkTime ? .blue : .green)
              Text(
                isCurrentlyWorkTime
                  ? "Work hours"
                  : "Personal hours"
              )
            }
          }

          if !configManager.validation.isValid {
            ForEach(configManager.validation.errors, id: \.self) { error in
              Label(
                error,
                systemImage: "exclamationmark.triangle.fill"
              )
              .foregroundStyle(.red)
              .font(.callout)
            }
          }
        } header: {
          Label("Status", systemImage: "info.circle")
        }
      }
      .formStyle(.grouped)
      .scrollDisabled(true)

      // Weekly schedule grid — outside Form so it can fill remaining space
      VStack(alignment: .leading, spacing: 6) {
        Label("Schedule Overview", systemImage: "calendar.badge.clock")
          .font(.system(.body))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 4)

        WeekScheduleGrid(
          startTime: scope == .local
            ? (configManager.localWorkStartTime ?? configManager.workStartTime)
            : configManager.workStartTime,
          endTime: scope == .local
            ? (configManager.localWorkEndTime ?? configManager.workEndTime)
            : configManager.workEndTime,
          startDay: scope == .local
            ? (configManager.localWorkStartDay ?? configManager.workStartDay)
            : configManager.workStartDay,
          endDay: scope == .local
            ? (configManager.localWorkEndDay ?? configManager.workEndDay)
            : configManager.workEndDay
        )
        .frame(minHeight: 80, maxHeight: .infinity)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 12)
    }
    .onAppear { syncDatesFromConfig() }
    .onChange(of: configManager.workStartTime) { syncDatesFromConfig() }
    .onChange(of: configManager.workEndTime) { syncDatesFromConfig() }
    .onChange(of: startDate) {
      let s = timeStringFromDate(startDate)
      if s != configManager.workStartTime {
        configManager.workStartTime = s
        autoSave()
      }
    }
    .onChange(of: endDate) {
      let s = timeStringFromDate(endDate)
      if s != configManager.workEndTime {
        configManager.workEndTime = s
        autoSave()
      }
    }
    .onChange(of: configManager.workStartDay) { autoSave() }
    .onChange(of: configManager.workEndDay) { autoSave() }
    .onChange(of: configManager.localWorkStartTime) { autoSave() }
    .onChange(of: configManager.localWorkEndTime) { autoSave() }
    .onChange(of: configManager.localWorkStartDay) { autoSave() }
    .onChange(of: configManager.localWorkEndDay) { autoSave() }
  }

  private func syncDatesFromConfig() {
    guard !configManager.isReloading else { return }
    let newStart = dateFromTimeString(configManager.workStartTime)
    let newEnd = dateFromTimeString(configManager.workEndTime)
    if timeStringFromDate(startDate) != configManager.workStartTime {
      startDate = newStart
    }
    if timeStringFromDate(endDate) != configManager.workEndTime {
      endDate = newEnd
    }
  }

  private func autoSave() {
    guard !configManager.isReloading else { return }
    if scope == .main {
      configManager.saveConfig()
    } else {
      configManager.saveLocalConfig()
    }
  }

  private var isNightShift: Bool {
    let startTime =
      scope == .local
      ? (configManager.localWorkStartTime ?? configManager.workStartTime)
      : configManager.workStartTime
    let endTime =
      scope == .local
      ? (configManager.localWorkEndTime ?? configManager.workEndTime)
      : configManager.workEndTime
    guard let start = parseTime(startTime), let end = parseTime(endTime) else {
      return false
    }
    return start >= end
  }

  private var isCurrentlyWorkTime: Bool {
    BrowserScheduleCore.isWorkTime(config: configManager.mergedConfig)
  }
}

// MARK: - Week Schedule Grid

private struct WeekScheduleGrid: View {
  let startTime: String
  let endTime: String
  let startDay: String
  let endDay: String

  private static let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  private static let hours = [0, 6, 12, 18, 24]

  private var startMinutes: Int { parseTime(startTime) ?? 0 }
  private var endMinutes: Int { parseTime(endTime) ?? 0 }
  private var isNightShift: Bool { startMinutes >= endMinutes }

  private var currentWeekday: Int {
    Calendar.current.component(.weekday, from: Date())
  }

  private var currentMinutes: Int {
    let cal = Calendar.current
    let now = Date()
    return cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
  }

  private func isWorkDay(_ dayName: String) -> Bool {
    guard let day = dayNameToWeekday(dayName),
      let startWd = dayNameToWeekday(startDay),
      let endWd = dayNameToWeekday(endDay)
    else { return false }
    if startWd <= endWd {
      return day >= startWd && day <= endWd
    } else {
      return day >= startWd || day <= endWd
    }
  }

  private func isToday(_ dayName: String) -> Bool {
    dayNameToWeekday(dayName) == currentWeekday
  }

  var body: some View {
    VStack(spacing: 0) {
      // Grid: hour labels on left, 7 day columns
      HStack(alignment: .top, spacing: 0) {
        // Hour labels column
        VStack(alignment: .trailing, spacing: 0) {
          ForEach(Self.hours, id: \.self) { hour in
            if hour == 24 {
              Text("\(hour)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(height: 0)
            } else {
              Text("\(hour)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxHeight: .infinity, alignment: .top)
            }
          }
        }
        .frame(width: 20)
        .offset(y: -4)

        // Day columns
        ForEach(Self.days, id: \.self) { day in
          VStack(spacing: 3) {
            // Day label
            Text(day)
              .font(.caption2)
              .fontWeight(isToday(day) ? .bold : .regular)
              .foregroundStyle(isToday(day) ? .primary : .secondary)

            // 24-hour bar
            GeometryReader { geo in
              let h = geo.size.height
              let workDay = isWorkDay(day)

              ZStack(alignment: .top) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                  .fill(Color.green.opacity(workDay ? 0.15 : 0.08))

                if workDay {
                  // Work hours fill
                  if isNightShift {
                    VStack(spacing: 0) {
                      // Top segment (midnight to end)
                      Rectangle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(height: h * CGFloat(endMinutes) / 1440.0)
                      Spacer()
                      // Bottom segment (start to midnight)
                      Rectangle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(height: h * CGFloat(1440 - startMinutes) / 1440.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                  } else {
                    Rectangle()
                      .fill(Color.blue.opacity(0.4))
                      .frame(height: h * CGFloat(endMinutes - startMinutes) / 1440.0)
                      .offset(y: h * CGFloat(startMinutes) / 1440.0)
                  }
                }

                // Current time marker (only on today)
                if isToday(day) {
                  Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
                    .offset(y: h * CGFloat(currentMinutes) / 1440.0 - 1)
                }
              }
            }
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Overridable Controls

private struct OverridableDatePicker: View {
  let label: String
  let inherited: String
  @Binding var override: String?
  @State private var pickerDate = dateFromTimeString("0:00")

  var body: some View {
    LabeledContent(label) {
      if override != nil {
        DatePicker(
          "",
          selection: $pickerDate,
          displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.stepperField)
        .labelsHidden()
        .onChange(of: pickerDate) {
          override = timeStringFromDate(pickerDate)
        }
        Button {
          override = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Clear override")
      } else {
        Text(inherited)
          .foregroundStyle(.secondary)
        Button("Override") {
          override = inherited
          pickerDate = dateFromTimeString(inherited)
        }
        .controlSize(.small)
      }
    }
    .onAppear {
      if let o = override {
        pickerDate = dateFromTimeString(o)
      }
    }
    .onChange(of: override) {
      if let o = override {
        let newDate = dateFromTimeString(o)
        if timeStringFromDate(pickerDate) != o {
          pickerDate = newDate
        }
      }
    }
  }
}

private struct OverridableDayPicker: View {
  let label: String
  let inherited: String
  @Binding var override: String?
  let options: [String]

  var body: some View {
    LabeledContent(label) {
      if override != nil {
        Picker(
          "",
          selection: Binding(
            get: { override ?? inherited },
            set: { override = $0 }
          )
        ) {
          ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .labelsHidden()
        .frame(width: 120)
        Button {
          override = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Clear override")
      } else {
        Text(inherited)
          .foregroundStyle(.secondary)
        Button("Override") { override = inherited }
          .controlSize(.small)
      }
    }
  }
}
