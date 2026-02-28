import BrowserScheduleCore
import SwiftUI

struct URLRulesView: View {
    @Environment(ConfigManager.self) private var configManager
    @Binding var scope: EditingScope
    @State private var newPersonalURL = ""
    @State private var newWorkURL = ""

    var body: some View {
        @Bindable var cm = configManager

        Form {
            Section {
                Picker("Editing", selection: $scope) {
                    Text("config.toml").tag(EditingScope.main)
                    Text("config.local.toml").tag(EditingScope.local)
                }
                .pickerStyle(.segmented)

                if scope == .local {
                    Label(
                        "Local URL rules are merged with config.toml rules, not replaced.",
                        systemImage: "info.circle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 16) {
                    URLListBox(
                        title: "Personal URLs",
                        icon: "house",
                        browserName: configManager.personalBrowser,
                        urls: personalUrlsBinding,
                        newURL: $newPersonalURL
                    )

                    URLListBox(
                        title: "Work URLs",
                        icon: "briefcase",
                        browserName: configManager.workBrowser,
                        urls: workUrlsBinding,
                        newURL: $newWorkURL
                    )
                }
            }

            HStack {
                Spacer()
                Button("Save") {
                    if scope == .main {
                        configManager.saveConfig()
                    } else {
                        configManager.saveLocalConfig()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var personalUrlsBinding: Binding<[String]> {
        @Bindable var cm = configManager
        if scope == .main {
            return $cm.personalUrls
        } else {
            return Binding(
                get: { configManager.localPersonalUrls ?? [] },
                set: { configManager.localPersonalUrls = $0.isEmpty ? nil : $0 }
            )
        }
    }

    private var workUrlsBinding: Binding<[String]> {
        @Bindable var cm = configManager
        if scope == .main {
            return $cm.workUrls
        } else {
            return Binding(
                get: { configManager.localWorkUrls ?? [] },
                set: { configManager.localWorkUrls = $0.isEmpty ? nil : $0 }
            )
        }
    }
}

// MARK: - URL List Box

private struct URLListBox: View {
    let title: String
    let icon: String
    let browserName: String
    @Binding var urls: [String]
    @Binding var newURL: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("URLs containing these patterns always open in **\(browserName)**")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                List {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, pattern in
                        HStack {
                            Text(pattern)
                                .font(.body.monospaced())
                            Spacer()
                            Button {
                                urls.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 120)

                HStack {
                    TextField("URL pattern", text: $newURL)
                        .onSubmit { addURL() }
                    Button {
                        addURL()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newURL.isEmpty)
                }
            }
            .padding(8)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    private func addURL() {
        let trimmed = newURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        urls.append(trimmed)
        newURL = ""
    }
}
