import SwiftUI
import BrowserScheduleCore

struct URLRulesView: View {
    @Environment(ConfigManager.self) private var configManager
    @State private var newPersonalURL = ""
    @State private var newWorkURL = ""

    var body: some View {
        @Bindable var cm = configManager

        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("URLs containing these patterns always open in **\(configManager.personalBrowser)**")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            List {
                                ForEach(Array(configManager.personalUrls.enumerated()), id: \.offset) { index, pattern in
                                    HStack {
                                        Text(pattern)
                                            .font(.body.monospaced())
                                        Spacer()
                                        Button {
                                            configManager.personalUrls.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(minHeight: 150)

                            HStack {
                                TextField("URL pattern", text: $newPersonalURL)
                                    .onSubmit { addPersonalURL() }
                                Button {
                                    addPersonalURL()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .disabled(newPersonalURL.isEmpty)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Label("Personal URLs", systemImage: "house")
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("URLs containing these patterns always open in **\(configManager.workBrowser)**")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            List {
                                ForEach(Array(configManager.workUrls.enumerated()), id: \.offset) { index, pattern in
                                    HStack {
                                        Text(pattern)
                                            .font(.body.monospaced())
                                        Spacer()
                                        Button {
                                            configManager.workUrls.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(minHeight: 150)

                            HStack {
                                TextField("URL pattern", text: $newWorkURL)
                                    .onSubmit { addWorkURL() }
                                Button {
                                    addWorkURL()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .disabled(newWorkURL.isEmpty)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Label("Work URLs", systemImage: "briefcase")
                    }
                }
            }

            HStack {
                Spacer()
                Button("Save") {
                    configManager.saveConfig()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addPersonalURL() {
        let trimmed = newPersonalURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        configManager.personalUrls.append(trimmed)
        newPersonalURL = ""
    }

    private func addWorkURL() {
        let trimmed = newWorkURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        configManager.workUrls.append(trimmed)
        newWorkURL = ""
    }
}
