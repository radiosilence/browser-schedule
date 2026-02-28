import BrowserScheduleCore
import SwiftUI

struct ConfigEditorView: View {
  @Environment(ConfigManager.self) private var configManager
  @State private var showDeleteConfirmation = false

  var body: some View {
    @Bindable var cm = configManager

    VStack(spacing: 0) {
      HSplitView {
        // Main config pane
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Label("config.toml", systemImage: "doc.text")
              .font(.headline)
            Text("(committed)")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
          }

          TOMLEditorView(text: $cm.rawConfigTOML)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
            )
        }
        .padding(10)
        .frame(minWidth: 280)

        // Local config pane
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Label("config.local.toml", systemImage: "doc.text.fill")
              .font(.headline)
            Text("(private)")
              .font(.caption)
              .foregroundStyle(.orange)
            Spacer()
          }

          if configManager.hasLocalConfig {
            TOMLEditorView(text: $cm.rawLocalConfigTOML)
              .clipShape(RoundedRectangle(cornerRadius: 6))
              .overlay(
                RoundedRectangle(cornerRadius: 6)
                  .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
              )
          } else {
            VStack(spacing: 8) {
              Spacer()
              Text("No local config file.")
                .foregroundStyle(.secondary)
              Text(
                "Local config is for private overrides that aren't committed to git."
              )
              .font(.callout)
              .foregroundStyle(.tertiary)
              .multilineTextAlignment(.center)
              Button("Create Local Config") {
                configManager.rawLocalConfigTOML =
                  "# Local overrides\n# Values here merge with config.toml\n"
                configManager.saveRawLocalConfig()
              }
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                  .separator.opacity(0.5),
                  style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
          }
        }
        .padding(10)
        .frame(minWidth: 280)
      }

      footerBar {
        if configManager.hasLocalConfig {
          Button("Delete Local Config", role: .destructive) {
            showDeleteConfirmation = true
          }
        }
        if let error = configManager.lastError {
          Label(error, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .font(.callout)
            .lineLimit(2)
        }
        Spacer()
        Button("Reload from Disk") {
          configManager.reload()
        }
        Button("Save Main") {
          configManager.saveRawConfig()
        }
        .controlSize(.large)
        if configManager.hasLocalConfig {
          Button("Save Local") {
            configManager.saveRawLocalConfig()
          }
          .controlSize(.large)
        }
      }
      .confirmationDialog(
        "Delete config.local.toml?",
        isPresented: $showDeleteConfirmation,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          configManager.deleteLocalConfig()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This will permanently delete your local config overrides.")
      }
    }
  }
}
