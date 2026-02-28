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
        TabView {
            GeneralView(scope: $scope)
                .tabItem { Label("General", systemImage: "gear") }

            ScheduleView(scope: $scope)
                .tabItem { Label("Schedule", systemImage: "clock") }

            URLRulesView(scope: $scope)
                .tabItem { Label("URL Rules", systemImage: "link") }

            ConfigEditorView()
                .tabItem { Label("Config Files", systemImage: "doc.text") }
        }
        .frame(minWidth: 660, minHeight: 500)
    }
}
