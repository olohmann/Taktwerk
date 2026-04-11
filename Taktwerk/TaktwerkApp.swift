import SwiftUI
import AppKit

@main
struct TaktwerkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Taktwerk Help") {
                    if let helpURL = Bundle.main.url(
                        forResource: "index",
                        withExtension: "html",
                        subdirectory: "TaktwerkHelp.help/Contents/Resources/en.lproj"
                    ) {
                        NSWorkspace.shared.open(helpURL)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
