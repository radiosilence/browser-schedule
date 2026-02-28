import BrowserScheduleCore
import SwiftUI

struct GeneralView: View {
    @Environment(ConfigManager.self) private var configManager
    @Binding var scope: EditingScope
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        @Bindable var cm = configManager

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Default Browser") {
                    HStack {
                        Image(
                            systemName: configManager.isDefaultBrowserStatus
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundStyle(configManager.isDefaultBrowserStatus ? .green : .red)
                        .font(.title2)

                        Text(
                            configManager.isDefaultBrowserStatus
                                ? "BrowserSchedule is the default browser"
                                : "BrowserSchedule is not the default browser")

                        Spacer()

                        Button("Set as Default Browser") {
                            do {
                                try registerAppBundle()
                                try setAsDefaultBrowser()
                                configManager.refreshDefaultBrowserStatus()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                        .disabled(configManager.isDefaultBrowserStatus)
                    }
                    .padding(8)
                }

                scopePicker

                GroupBox("Browsers") {
                    VStack(alignment: .leading, spacing: 12) {
                        if scope == .main {
                            row("Work Browser") {
                                BrowserPicker(selection: $cm.workBrowser)
                            }
                            row("Personal Browser") {
                                BrowserPicker(selection: $cm.personalBrowser)
                            }
                        } else {
                            OverridableField(
                                label: "Work Browser",
                                inherited: configManager.workBrowser,
                                override: $cm.localWorkBrowser
                            ) { binding in
                                BrowserPicker(selection: binding)
                            }
                            OverridableField(
                                label: "Personal Browser",
                                inherited: configManager.personalBrowser,
                                override: $cm.localPersonalBrowser
                            ) { binding in
                                BrowserPicker(selection: binding)
                            }
                        }

                        HStack {
                            Spacer()
                            saveButton
                        }
                    }
                    .padding(8)
                }
            }
            .padding(16)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func row(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            content()
        }
    }

    private var scopePicker: some View {
        Picker("Editing", selection: $scope) {
            Text("config.toml").tag(EditingScope.main)
            Text("config.local.toml").tag(EditingScope.local)
        }
        .pickerStyle(.segmented)
    }

    private var saveButton: some View {
        Button("Save") {
            if scope == .main {
                configManager.saveConfig()
            } else {
                configManager.saveLocalConfig()
            }
        }
    }
}

// MARK: - Overridable Field

struct OverridableField<Content: View>: View {
    let label: String
    let inherited: String
    @Binding var override: String?
    @ViewBuilder let content: (Binding<String>) -> Content

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            if override != nil {
                content(
                    Binding(
                        get: { override ?? "" },
                        set: { override = $0 }
                    ))
                Button {
                    override = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear override, inherit from config.toml")
            } else {
                Text(inherited)
                    .foregroundStyle(.secondary)
                Button("Override") {
                    override = inherited
                }
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Browser Picker

struct BrowserPicker: View {
    @Binding var selection: String
    @State private var browsers: [BrowserInfo] = []

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $selection) {
                ForEach(browsers, id: \.bundleID) { browser in
                    Text(browser.name).tag(browser.name)
                }
                if !browsers.contains(where: { $0.name == selection }) && !selection.isEmpty {
                    Text(selection).tag(selection)
                }
            }
            .labelsHidden()
            .frame(width: 180)

            TextField("Custom", text: $selection)
                .frame(width: 100)
        }
        .onAppear {
            browsers = getInstalledBrowsers()
        }
    }
}
