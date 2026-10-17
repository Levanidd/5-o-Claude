import SwiftUI

enum Tab: Hashable { case home, money, capture, family }

struct MainTabView: View {
    @Environment(AppState.self) private var app
    @State private var tab: Tab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView(goTo: { tab = $0 })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)
            MoneyView()
                .tabItem { Label("Money", systemImage: "eurosign.circle") }
                .tag(Tab.money)
            CaptureView()
                .tabItem { Label("Capture", systemImage: "plus.viewfinder") }
                .tag(Tab.capture)
            FamilyView()
                .tabItem { Label("Family", systemImage: "person.2") }
                .tag(Tab.family)
        }
        .tint(Color.green800)
    }
}
