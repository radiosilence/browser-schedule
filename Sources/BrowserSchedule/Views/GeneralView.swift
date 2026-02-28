import BrowserScheduleCore
import SwiftUI

struct GeneralView: View {
    @Environment(ConfigManager.self) private var configManager
    @Binding var scope: EditingScope
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        @Bindable var cm = configManager

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Default Browser status
                    GroupBox {
                        HStack(spacing: 12) {
                            Image(
                                systemName: configManager.isDefaultBrowserStatus
                                    ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundStyle(
                                configManager.isDefaultBrowserStatus ? .green : .red
                            )
                            .font(.title2)

                            Text(
                                configManager.isDefaultBrowserStatus
                                    ? "BrowserSchedule is the default browser"
                                    : "BrowserSchedule is not the default browser")

                            Spacer()

                            Button("Set as Default Browser") {
                                do {
                                    try registerAppBundle()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                    return
                                }
                                setAsDefaultBrowser()
                                // Poll for the user confirming the OS prompt
                                for delay in [1.0, 3.0, 6.0, 10.0] {
                                    DispatchQueue.main.asyncAfter(
                                        deadline: .now() + delay
                                    ) {
                                        configManager.refreshDefaultBrowserStatus()
                                    }
                                }
                            }
                            .disabled(configManager.isDefaultBrowserStatus)
                        }
                        .padding(4)
                    } label: {
                        Label("Default Browser", systemImage: "globe")
                    }

                    Picker("Editing", selection: $scope) {
                        Text("config.toml").tag(EditingScope.main)
                        Text("config.local.toml").tag(EditingScope.local)
                    }
                    .pickerStyle(.segmented)

                    // Browsers
                    GroupBox {
                        VStack(spacing: 0) {
                            if scope == .main {
                                browserRow("Work Browser") {
                                    BrowserPicker(selection: $cm.workBrowser)
                                }
                                Divider().padding(.horizontal, -4)
                                browserRow("Personal Browser") {
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
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                Divider().padding(.horizontal, -4)
                                OverridableField(
                                    label: "Personal Browser",
                                    inherited: configManager.personalBrowser,
                                    override: $cm.localPersonalBrowser
                                ) { binding in
                                    BrowserPicker(selection: binding)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                            }
                        }
                    } label: {
                        Label("Browsers", systemImage: "app.dashed")
                    }
                }
                .padding(20)
            }

            footerBar {
                if let error = configManager.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
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
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func browserRow(
        _ label: String, @ViewBuilder content: () -> some View
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
            Spacer()
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
        Picker("", selection: $selection) {
            ForEach(browsers, id: \.bundleID) { browser in
                Text(browser.name).tag(browser.name)
            }
            if !browsers.contains(where: { $0.name == selection }) && !selection.isEmpty {
                Text(selection).tag(selection)
            }
        }
        .labelsHidden()
        .frame(width: 200)
        .onAppear {
            browsers = getInstalledBrowsers()
        }
    }
}

// MARK: - Footer Bar

func footerBar(@ViewBuilder content: () -> some View) -> some View {
    VStack(spacing: 0) {
        Divider()
        HStack {
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
