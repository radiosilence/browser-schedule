import SwiftUI
import BrowserScheduleCore

struct ScheduleView: View {
    @Environment(ConfigManager.self) private var configManager

    private let dayOptions = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        @Bindable var cm = configManager

        Form {
            Section {
                GroupBox("Work Schedule") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Work Start Time") {
                            TextField("HH:MM", text: $cm.workStartTime)
                                .frame(width: 80)
                        }

                        LabeledContent("Work End Time") {
                            TextField("HH:MM", text: $cm.workEndTime)
                                .frame(width: 80)
                        }

                        LabeledContent("Work Start Day") {
                            Picker("", selection: $cm.workStartDay) {
                                ForEach(dayOptions, id: \.self) { day in
                                    Text(day).tag(day)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }

                        LabeledContent("Work End Day") {
                            Picker("", selection: $cm.workEndDay) {
                                ForEach(dayOptions, id: \.self) { day in
                                    Text(day).tag(day)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }

                        Divider()

                        if isNightShift {
                            Label("Night shift detected (hours span midnight)", systemImage: "moon.fill")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }

                        HStack {
                            Image(systemName: isCurrentlyWorkTime ? "briefcase.fill" : "house.fill")
                                .foregroundStyle(isCurrentlyWorkTime ? .blue : .green)
                            Text(isCurrentlyWorkTime ? "Currently in work hours" : "Currently in personal hours")
                                .font(.callout)
                        }

                        if !configManager.validation.isValid {
                            ForEach(configManager.validation.errors, id: \.self) { error in
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.callout)
                            }
                        }

                        HStack {
                            Spacer()
                            Button("Save") {
                                configManager.saveConfig()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var isNightShift: Bool {
        guard let start = parseTime(configManager.workStartTime),
              let end = parseTime(configManager.workEndTime)
        else { return false }
        return start >= end
    }

    private var isCurrentlyWorkTime: Bool {
        let config = Config(
            browsers: Config.Browsers(),
            workTime: Config.WorkTime(start: configManager.workStartTime, end: configManager.workEndTime),
            workDays: Config.WorkDays(start: configManager.workStartDay, end: configManager.workEndDay)
        )
        return BrowserScheduleCore.isWorkTime(config: config)
    }
}
