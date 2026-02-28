import BrowserScheduleCore
import SwiftUI

struct URLRulesView: View {
  @Environment(ConfigManager.self) private var configManager
  @Binding var scope: EditingScope
  @State private var newPersonalURL = ""
  @State private var newWorkURL = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if scope == .local {
        Label(
          "Local URL rules are merged with config.toml rules, not replaced.",
          systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.top, 12)
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
      .padding(20)

      if let error = configManager.lastError {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
          .font(.callout)
          .padding(.horizontal, 20)
          .padding(.bottom, 8)
      }
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
      VStack(alignment: .leading, spacing: 0) {
        Text("Patterns always open in **\(browserName)**")
          .font(.callout)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.top, 8)
          .padding(.bottom, 6)

        ScrollView {
          VStack(spacing: 0) {
            if urls.wrappedValue.isEmpty {
              HStack {
                Spacer()
                Text("No patterns — URLs follow the schedule")
                  .foregroundStyle(.tertiary)
                  .font(.callout)
                Spacer()
              }
              .padding(.vertical, 20)
            } else {
              ForEach(
                Array(urls.wrappedValue.enumerated()), id: \.offset
              ) { index, pattern in
                if index > 0 {
                  Divider()
                }
                HStack {
                  Text(pattern)
                    .font(.body.monospaced())
                  Spacer()
                  Button {
                    urls.wrappedValue.remove(at: index)
                    autoSave()
                  } label: {
                    Image(systemName: "minus.circle.fill")
                      .foregroundStyle(.red)
                  }
                  .buttonStyle(.borderless)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
              }
            }
          }
        }
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.horizontal, 8)

        Divider()
          .padding(.vertical, 6)

        HStack(spacing: 8) {
          TextField("e.g. github.com", text: newURL)
            .textFieldStyle(.roundedBorder)
            .onSubmit { addURL(urls: urls, newURL: newURL) }
          Button {
            addURL(urls: urls, newURL: newURL)
          } label: {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(Color.accentColor)
          }
          .buttonStyle(.borderless)
          .disabled(newURL.wrappedValue.isEmpty)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
      }
    } label: {
      Label(title, systemImage: icon)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func addURL(urls: Binding<[String]>, newURL: Binding<String>) {
    let trimmed = newURL.wrappedValue.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    // Duplicate detection
    guard !urls.wrappedValue.contains(trimmed) else {
      newURL.wrappedValue = ""
      return
    }
    urls.wrappedValue.append(trimmed)
    newURL.wrappedValue = ""
    autoSave()
  }

  private func autoSave() {
    if scope == .main {
      configManager.saveConfig()
    } else {
      configManager.saveLocalConfig()
    }
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
