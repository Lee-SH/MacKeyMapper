import SwiftUI

@main
struct MacKeyMapperApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup("MacKeyMapper") {
            ContentView()
                .environmentObject(state)
                .onAppear { state.start() }
                .frame(minWidth: 900, minHeight: 360)
        }
        .windowResizability(.contentSize)
    }
}
