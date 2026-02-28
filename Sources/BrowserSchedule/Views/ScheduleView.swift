import BrowserScheduleCore
import SwiftUI

struct ScheduleView: View {
    @Environment(ConfigManager.self) private var configManager
    @Binding var scope: EditingScope

    private let dayOptions = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        @Bindable var cm = configManager

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Editing", selection: $scope) {
                        Text("config.toml").tag(EditingScope.main)
                        Text("config.local.toml").tag(EditingScope.local)
                    }
                    .pickerStyle(.segmented)

                    // Work Hours
                    GroupBox {
                        VStack(spacing: 0) {
                            if scope == .main {
                                scheduleRow("Start Time") {
                                    TextField("9:00", text: $cm.workStartTime)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }
                                Divider().padding(.horizontal, -4)
                                scheduleRow("End Time") {
                                    TextField("18:00", text: $cm.workEndTime)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }
                            } else {
                                OverridableTextField(
                                    label: "Start Time",
                                    placeholder: "9:00",
                                    inherited: configManager.workStartTime,
                                    override: $cm.localWorkStartTime
                                )
                                Divider().padding(.horizontal, -4)
                                OverridableTextField(
                                    label: "End Time",
                                    placeholder: "18:00",
                                    inherited: configManager.workEndTime,
                                    override: $cm.localWorkEndTime
                                )
                            }

                            if isNightShift {
                                Divider().padding(.horizontal, -4)
                                HStack {
                                    Label(
                                        "Night shift detected (hours span midnight)",
                                        systemImage: "moon.fill"
                                    )
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                        }
                    } label: {
                        Label("Work Hours", systemImage: "clock")
                    }

                    // Work Days
                    GroupBox {
                        VStack(spacing: 0) {
                            if scope == .main {
                                scheduleRow("Start Day") {
                                    Picker("", selection: $cm.workStartDay) {
                                        ForEach(dayOptions, id: \.self) { Text($0).tag($0) }
                                    }
                                    .labelsHidden()
                                    .frame(width: 120)
                                }
                                Divider().padding(.horizontal, -4)
                                scheduleRow("End Day") {
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
                                Divider().padding(.horizontal, -4)
                                OverridableDayPicker(
                                    label: "End Day",
                                    inherited: configManager.workEndDay,
                                    override: $cm.localWorkEndDay,
                                    options: dayOptions
                                )
                            }
                        }
                    } label: {
                        Label("Work Days", systemImage: "calendar")
                    }

                    // Status
                    GroupBox {
                        HStack(spacing: 12) {
                            Image(
                                systemName: isCurrentlyWorkTime
                                    ? "briefcase.fill" : "house.fill"
                            )
                            .foregroundStyle(isCurrentlyWorkTime ? .blue : .green)
                            .font(.title3)
                            Text(
                                isCurrentlyWorkTime
                                    ? "Currently in work hours"
                                    : "Currently in personal hours"
                            )

                            Spacer()

                            if !configManager.validation.isValid {
                                VStack(alignment: .trailing, spacing: 4) {
                                    ForEach(
                                        configManager.validation.errors, id: \.self
                                    ) { error in
                                        Label(
                                            error,
                                            systemImage: "exclamationmark.triangle.fill"
                                        )
                                        .foregroundStyle(.red)
                                        .font(.callout)
                                    }
                                }
                            }
                        }
                        .padding(4)
                    } label: {
                        Label("Status", systemImage: "info.circle")
                    }
                }
                .padding(20)
            }

            footerBar {
                Spacer()
                Button("Save") {
                    if scope == .main {
                        configManager.saveConfig()
                    } else {
                        configManager.saveLocalConfig()
                    }
                }
                .controlSize(.large)
            }
        }
    }

    private func scheduleRow(
        _ label: String, @ViewBuilder content: () -> some View
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
            content()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

// MARK: - Overridable Controls

private struct OverridableTextField: View {
    let label: String
    let placeholder: String
    let inherited: String
    @Binding var override: String?

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
            if override != nil {
                TextField(
                    placeholder,
                    text: Binding(
                        get: { override ?? "" },
                        set: { override = $0 }
                    )
                )
                .textFieldStyle(.roundedBorder)
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
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct OverridableDayPicker: View {
    let label: String
    let inherited: String
    @Binding var override: String?
    let options: [String]

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
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
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
