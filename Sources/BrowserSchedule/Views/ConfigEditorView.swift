import SwiftUI
import BrowserScheduleCore

struct ConfigEditorView: View {
    @Environment(ConfigManager.self) private var configManager

    var body: some View {
        @Bindable var cm = configManager

        VStack(spacing: 12) {
            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("config.toml", systemImage: "doc.text")
                            .font(.headline)
                        Spacer()
                        Button("Save") {
                            configManager.saveRawConfig()
                        }
                    }

                    TextEditor(text: $cm.rawConfigTOML)
                        .font(.body.monospaced())
                        .scrollContentBackground(.visible)
                }
                .padding(8)
                .frame(minWidth: 280)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("config.local.toml", systemImage: "doc.text.fill")
                            .font(.headline)
                        Spacer()

                        if configManager.hasLocalConfig {
                            Button("Save") {
                                configManager.saveRawLocalConfig()
                            }
                        }
                    }

                    if configManager.hasLocalConfig {
                        TextEditor(text: $cm.rawLocalConfigTOML)
                            .font(.body.monospaced())
                            .scrollContentBackground(.visible)
                    } else {
                        VStack {
                            Spacer()
                            Text("No local config file exists.")
                                .foregroundStyle(.secondary)
                            Text("Local config is for private overrides that aren't checked into git.")
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                                .padding(.bottom, 4)
                            Button("Create Local Config") {
                                configManager.rawLocalConfigTOML = "# Local overrides\n# Values here merge with config.toml\n"
                                configManager.saveRawLocalConfig()
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(8)
                .frame(minWidth: 280)
            }

            HStack {
                if let error = configManager.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                Spacer()
                Button("Reload from Disk") {
                    configManager.reload()
                }
            }
        }
        .padding(.top, 8)
    }
}
