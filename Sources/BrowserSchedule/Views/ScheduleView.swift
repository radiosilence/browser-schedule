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

    Form {
      // Work Hours
      Section {
        if scope == .main {
          DatePicker("Start Time", selection: $startDate, displayedComponents: .hourAndMinute)
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

      // Timeline
      Section {
        TimelineBar(
          startTime: scope == .local
            ? (configManager.localWorkStartTime ?? configManager.workStartTime)
            : configManager.workStartTime,
          endTime: scope == .local
            ? (configManager.localWorkEndTime ?? configManager.workEndTime)
            : configManager.workEndTime
        )
      } header: {
        Label("Schedule Overview", systemImage: "chart.bar.fill")
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

// MARK: - Timeline Bar

private struct TimelineBar: View {
  let startTime: String
  let endTime: String

  private var startMinutes: Int { parseTime(startTime) ?? 0 }
  private var endMinutes: Int { parseTime(endTime) ?? 0 }
  private var isNightShift: Bool { startMinutes >= endMinutes }

  private var currentMinutes: Int {
    let cal = Calendar.current
    let now = Date()
    return cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
  }

  var body: some View {
    VStack(spacing: 4) {
      GeometryReader { geo in
        let w = geo.size.width

        ZStack(alignment: .leading) {
          // Personal hours background
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.green.opacity(0.2))
            .frame(height: 24)

          // Work segment(s)
          if isNightShift {
            // Night shift: two segments at edges
            HStack(spacing: 0) {
              Rectangle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: w * CGFloat(endMinutes) / 1440.0)
              Spacer()
              Rectangle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: w * CGFloat(1440 - startMinutes) / 1440.0)
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
          } else {
            // Day shift: single segment
            Rectangle()
              .fill(Color.blue.opacity(0.35))
              .frame(
                width: w * CGFloat(endMinutes - startMinutes) / 1440.0,
                height: 24
              )
              .offset(x: w * CGFloat(startMinutes) / 1440.0)
          }

          // Current time marker
          Rectangle()
            .fill(Color.red)
            .frame(width: 2, height: 28)
            .offset(x: w * CGFloat(currentMinutes) / 1440.0 - 1)
        }
      }
      .frame(height: 28)

      // Hour labels
      HStack {
        Text("0").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Text("6").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Text("12").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Text("18").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Text("24").font(.caption2).foregroundStyle(.secondary)
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
