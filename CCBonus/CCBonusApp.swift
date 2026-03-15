import SwiftUI

@main
struct CCBonusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 320, height: 400)
        .windowResizability(.contentSize)
    }
}
