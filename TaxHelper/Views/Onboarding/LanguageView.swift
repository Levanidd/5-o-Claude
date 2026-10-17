import SwiftUI

struct LanguageView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack(alignment: .topTrailing) {
            EuroBackdrop()
            VStack(alignment: .leading, spacing: Space.xxl) {
                Spacer().frame(height: Space.xxl)
                Text("Family Support Check")
                    .font(.caption13)
                    .foregroundStyle(Color.green800)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.green100, in: Capsule())
                Text("Which language do you prefer?")
                    .font(.title)
                    .foregroundStyle(Color.ink900)
                Text("Everything is explained in your language. Letters to German offices are written in German for you.")
                    .font(.body17)
                    .foregroundStyle(Color.ink500)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.md) {
                    ForEach(Lang.allCases) { lang in
                        Button {
                            Haptics.tap()
                            app.language = lang
                        } label: {
                            HStack {
                                Text(lang.flag)
                                Text(lang.name).font(.system(size: 17, weight: .medium))
                                Spacer()
                                if app.language == lang {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green500)
                                }
                            }
                            .foregroundStyle(Color.ink900)
                            .padding(Space.lg)
                            .background(Color.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(app.language == lang ? Color.green500 : Color.border, lineWidth: app.language == lang ? 2 : 1)
                            )
                        }
                        .accessibilityLabel(lang.name)
                    }
                }

                Spacer()
                Button("Continue") { app.stage = .welcome }
                    .buttonStyle(.primary)
            }
            .padding(Space.xl)
        }
        .screenBackground()
    }
}
