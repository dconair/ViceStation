import SwiftUI

@main
struct ViceStationApp: App {
    @State private var library = StationLibrary()
    @State private var player = RadioPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(player)
                .preferredColorScheme(.dark)
                .task {
                    library.bootstrap()
                    player.attach(library: library)
                }
        }
    }
}
