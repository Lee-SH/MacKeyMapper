import SwiftUI

@main
struct MacKeyMapperApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup("MacKeyMapper") {
            ContentView()
                .environmentObject(state)
                .onAppear { state.start() }
        }
        .windowResizability(.contentSize)
    }
}
