import BrowserScheduleCore
import SwiftUI

// MARK: - Settings Row Style

struct SettingsRowStyle: LabeledContentStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
      Spacer()
      configuration.content
    }
  }
}

struct GeneralView: View {
  @Environment(ConfigManager.self) private var configManager
  @Binding var scope: EditingScope
  @State private var errorMessage: String?
  @State private var showError = false

  var body: some View {
    @Bindable var cm = configManager

    ScrollView {
      VStack(spacing: 16) {
        // Default Browser status
        GroupBox {
          LabeledContent("Status") {
            HStack(spacing: 8) {
              Image(
                systemName: configManager.isDefaultBrowserStatus
                  ? "checkmark.circle.fill" : "xmark.circle.fill"
              )
              .foregroundStyle(
                configManager.isDefaultBrowserStatus ? .green : .red
              )

              Text(
                configManager.isDefaultBrowserStatus
                  ? "BrowserSchedule is the default browser"
                  : "Not the default browser")

              if !configManager.isDefaultBrowserStatus {
                Button("Set as Default") {
                  do {
                    try registerAppBundle()
                  } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                  }
                  setAsDefaultBrowser()
                  for delay in [1.0, 3.0, 6.0, 10.0] {
                    DispatchQueue.main.asyncAfter(
                      deadline: .now() + delay
                    ) {
                      configManager.refreshDefaultBrowserStatus()
                    }
                  }
                }
              }
            }
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 6)
        } label: {
          Label("Default Browser", systemImage: "globe")
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Current routing status
        GroupBox {
          VStack(spacing: 0) {
            LabeledContent("Active Browser") {
              HStack(spacing: 8) {
                Image(
                  systemName: isCurrentlyWorkTime
                    ? "briefcase.fill" : "house.fill"
                )
                .foregroundStyle(isCurrentlyWorkTime ? .blue : .green)

                Text(
                  isCurrentlyWorkTime
                    ? "\(configManager.mergedConfig.browsers.work) (work hours)"
                    : "\(configManager.mergedConfig.browsers.personal) (personal hours)"
                )
              }
            }
            .padding(.vertical, 4)

            if !configManager.validation.isValid {
              ForEach(configManager.validation.errors, id: \.self) { error in
                Divider()
                Label(error, systemImage: "exclamationmark.triangle.fill")
                  .foregroundStyle(.red)
                  .font(.callout)
                  .padding(.vertical, 4)
              }
            }
          }
          .padding(.horizontal, 6)
        } label: {
          Label("Routing", systemImage: "arrow.triangle.branch")
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Browsers
        GroupBox {
          VStack(spacing: 0) {
            if scope == .main {
              LabeledContent("Work Browser") {
                BrowserPicker(selection: $cm.workBrowser)
              }
              .padding(.vertical, 4)
              Divider()
              LabeledContent("Personal Browser") {
                BrowserPicker(selection: $cm.personalBrowser)
              }
              .padding(.vertical, 4)
            } else {
              OverridableField(
                label: "Work Browser",
                inherited: configManager.workBrowser,
                override: $cm.localWorkBrowser
              ) { binding in
                BrowserPicker(selection: binding)
              }
              .padding(.vertical, 4)
              Divider()
              OverridableField(
                label: "Personal Browser",
                inherited: configManager.personalBrowser,
                override: $cm.localPersonalBrowser
              ) { binding in
                BrowserPicker(selection: binding)
              }
              .padding(.vertical, 4)
            }
          }
          .padding(.horizontal, 6)
        } label: {
          Label("Browsers", systemImage: "app.dashed")
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let error = configManager.lastError {
          GroupBox {
            Label(error, systemImage: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
              .padding(.vertical, 4)
          }
        }
      }
      .labeledContentStyle(SettingsRowStyle())
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .onChange(of: configManager.workBrowser) { autoSave() }
    .onChange(of: configManager.personalBrowser) { autoSave() }
    .onChange(of: configManager.localWorkBrowser) { autoSave() }
    .onChange(of: configManager.localPersonalBrowser) { autoSave() }
    .alert("Error", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage ?? "Unknown error")
    }
  }

  private func autoSave() {
    guard !configManager.isReloading else { return }
    if scope == .main {
      configManager.saveConfig()
    } else {
      configManager.saveLocalConfig()
    }
  }

  private var isCurrentlyWorkTime: Bool {
    BrowserScheduleCore.isWorkTime(config: configManager.mergedConfig)
  }
}

// MARK: - Overridable Field

struct OverridableField<Content: View>: View {
  let label: String
  let inherited: String
  @Binding var override: String?
  @ViewBuilder let content: (Binding<String>) -> Content

  var body: some View {
    LabeledContent(label) {
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

  private var selectedIcon: NSImage? {
    browsers.first(where: { $0.name == selection })?.icon
  }

  var body: some View {
    HStack(spacing: 6) {
      Menu {
        ForEach(browsers, id: \.bundleID) { browser in
          Button {
            selection = browser.name
          } label: {
            Label {
              Text(browser.name)
            } icon: {
              Image(nsImage: browser.icon)
            }
          }
        }
        if !browsers.contains(where: { $0.name == selection })
          && !selection.isEmpty
        {
          Divider()
          Button(selection) {}.disabled(true)
        }
      } label: {
        HStack(spacing: 6) {
          if let icon = selectedIcon {
            Image(nsImage: icon)
          }
          Text(selection.isEmpty ? "Select..." : selection)
          Image(systemName: "chevron.up.chevron.down")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .menuStyle(.borderlessButton)
      .frame(width: 200)

      Button("Other\u{2026}") {
        pickApplication()
      }
      .controlSize(.small)
    }
    .onAppear {
      browsers = getInstalledBrowsers()
    }
  }

  private func pickApplication() {
    let panel = NSOpenPanel()
    panel.title = "Choose Application"
    panel.allowedContentTypes = [.application]
    panel.allowsMultipleSelection = false
    panel.directoryURL = URL(fileURLWithPath: "/Applications")

    guard panel.runModal() == .OK, let url = panel.url else { return }
    let name =
      Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? url.deletingPathExtension().lastPathComponent
    selection = name
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
