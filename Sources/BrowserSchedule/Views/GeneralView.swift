import SwiftUI
import BrowserScheduleCore

struct GeneralView: View {
    @Environment(ConfigManager.self) private var configManager
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        @Bindable var cm = configManager

        Form {
            Section {
                GroupBox("Default Browser") {
                    HStack {
                        Image(systemName: configManager.isDefaultBrowserStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(configManager.isDefaultBrowserStatus ? .green : .red)
                            .font(.title2)

                        Text(configManager.isDefaultBrowserStatus
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
                    .padding(.vertical, 4)
                }

                GroupBox("Browsers") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Work Browser") {
                            BrowserPicker(selection: $cm.workBrowser)
                        }

                        LabeledContent("Personal Browser") {
                            BrowserPicker(selection: $cm.personalBrowser)
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
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

private struct BrowserPicker: View {
    @Binding var selection: String
    @State private var browsers: [BrowserInfo] = []

    var body: some View {
        HStack {
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

            TextField("Custom", text: $selection)
                .frame(width: 120)
        }
        .onAppear {
            browsers = getInstalledBrowsers()
        }
    }
}
