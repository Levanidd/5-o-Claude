import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Group {
            switch app.stage {
            case .language: LanguageView()
            case .welcome: WelcomeView()
            case .profile: ProfileFlowView()
            case .result: ResultView()
            case .main: MainTabView()
            }
        }
        .animation(.smooth, value: app.stage)
        .environment(\.layoutDirection, app.language == .ar ? .rightToLeft : .leftToRight)
    }
}

#Preview {
    ContentView().environment(AppState())
}
