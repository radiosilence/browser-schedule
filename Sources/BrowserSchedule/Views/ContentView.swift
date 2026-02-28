import BrowserScheduleCore
import SwiftUI

enum EditingScope: String, CaseIterable {
  case main = "config.toml"
  case local = "config.local.toml"
}

struct ContentView: View {
  @Environment(ConfigManager.self) private var configManager
  @State private var scope: EditingScope = .main

  var body: some View {
    VStack(spacing: 0) {
      Picker("Editing", selection: $scope) {
        Text("config.toml").tag(EditingScope.main)
        Text("config.local.toml").tag(EditingScope.local)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 4)

      TabView {
        GeneralView(scope: $scope)
          .tabItem { Label("General", systemImage: "gear") }

        ScheduleView(scope: $scope)
          .tabItem { Label("Schedule", systemImage: "clock") }

        URLRulesView(scope: $scope)
          .tabItem { Label("URL Rules", systemImage: "link") }

        ConfigEditorView(scope: $scope)
          .tabItem { Label("Config Files", systemImage: "doc.text") }
      }
    }
    .frame(minWidth: 660, minHeight: 480)
  }
}
