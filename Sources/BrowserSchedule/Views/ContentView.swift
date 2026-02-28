import SwiftUI
import BrowserScheduleCore

struct ContentView: View {
    @Environment(ConfigManager.self) private var configManager

    var body: some View {
        TabView {
            GeneralView()
                .tabItem { Label("General", systemImage: "gear") }

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "clock") }

            URLRulesView()
                .tabItem { Label("URL Rules", systemImage: "link") }

            ConfigEditorView()
                .tabItem { Label("Config Files", systemImage: "doc.text") }
        }
        .frame(minWidth: 600, minHeight: 450)
        .padding()
    }
}
