import SwiftUI

@main
struct TaxHelperApp: App {
    @State private var app = AppState()

    init() {
        AIService.dropStaleOverride()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .preferredColorScheme(.light)
        }
    }
}
