import SwiftUI
import ZorkUI

@main
struct ZorkApp: App {
    var body: some Scene {
        WindowGroup {
            ZorkGameView()
                .preferredColorScheme(.dark)
        }
    }
}
