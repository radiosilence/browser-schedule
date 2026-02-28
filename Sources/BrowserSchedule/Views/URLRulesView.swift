import BrowserScheduleCore
import SwiftUI

struct URLRulesView: View {
    @Environment(ConfigManager.self) private var configManager
    @Binding var scope: EditingScope
    @State private var newPersonalURL = ""
    @State private var newWorkURL = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                    urlListBox(
                        title: "Personal URLs",
                        icon: "house",
                        browserName: configManager.personalBrowser,
                        urls: personalUrlsBinding,
                        newURL: $newPersonalURL
                    )

                    urlListBox(
                        title: "Work URLs",
                        icon: "briefcase",
                        browserName: configManager.workBrowser,
                        urls: workUrlsBinding,
                        newURL: $newWorkURL
                    )
                }

                HStack {
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
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func urlListBox(
        title: String,
        icon: String,
        browserName: String,
        urls: Binding<[String]>,
        newURL: Binding<String>
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("URLs containing these patterns always open in **\(browserName)**")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(spacing: 2) {
                    ForEach(Array(urls.wrappedValue.enumerated()), id: \.offset) { index, pattern in
                        HStack {
                            Text(pattern)
                                .font(.body.monospaced())
                            Spacer()
                            Button {
                                urls.wrappedValue.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            index % 2 == 0
                                ? Color.clear
                                : Color.primary.opacity(0.03)
                        )
                    }
                }
                .frame(minHeight: 80)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 4))

                HStack {
                    TextField("URL pattern", text: newURL)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addURL(urls: urls, newURL: newURL) }
                    Button {
                        addURL(urls: urls, newURL: newURL)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .disabled(newURL.wrappedValue.isEmpty)
                }
            }
            .padding(8)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    private func addURL(urls: Binding<[String]>, newURL: Binding<String>) {
        let trimmed = newURL.wrappedValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        urls.wrappedValue.append(trimmed)
        newURL.wrappedValue = ""
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
